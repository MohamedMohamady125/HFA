import random
import string
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from app.database import get_connection, get_cursor
from app.deps import get_current_user
from app.schemas import UserCreate, UserLogin
from passlib.hash import bcrypt
from jose import jwt
from app.config import settings
from app.utils.email import send_reset_email
from app.utils.tokens import create_reset_token
from app.utils.db_helpers import get_user_by_email

router = APIRouter()

@router.post("/register")
def register(user: UserCreate):
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT id FROM registration_requests WHERE email = %s", (user.email,))
    if cursor.fetchone():
        raise HTTPException(status_code=400, detail="Email already submitted")

    cursor.execute("SELECT name FROM branches WHERE id = %s", (user.branch_id,))
    branch = cursor.fetchone()
    if not branch:
        raise HTTPException(status_code=400, detail="Branch not found")

    branch_name = branch["name"]

    cursor.execute(
        "INSERT INTO registration_requests (athlete_name, phone, email, password_hash, branch_name) VALUES (%s, %s, %s, %s, %s)",
        (user.name, user.phone, user.email, bcrypt.hash(user.password), branch_name)
    )
    conn.commit()

    cursor.execute("SELECT id FROM users WHERE role = 'coach' AND branch_id = %s LIMIT 1", (user.branch_id,))
    coach = cursor.fetchone()
    if coach:
        cursor.execute(
            "INSERT INTO notifications (user_id, message, type) VALUES (%s, %s, 'alert')",
            (coach["id"], f"New registration request for {branch_name}")
        )
        conn.commit()

    cursor.close()
    conn.close()
    return {"message": "Request submitted. A coach will review and approve it."}


@router.post("/login")
def login(user: UserLogin):
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT * FROM users WHERE email = %s", (user.email,))
    db_user = cursor.fetchone()

    if not db_user or not bcrypt.verify(user.password, db_user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if db_user["role"] == "athlete" and db_user.get("approved", False):
        cursor.execute("SELECT 1 FROM athletes WHERE user_id = %s", (db_user["id"],))
        if not cursor.fetchone():
            cursor.execute("INSERT INTO athletes (id, user_id) VALUES (%s, %s)", (db_user["id"], db_user["id"]))
            conn.commit()

    token = jwt.encode(
        {"sub": str(db_user["id"])},
        settings.JWT_SECRET,
        algorithm=settings.JWT_ALGORITHM,
    )

    cursor.close()
    conn.close()

    return {
        "token": token,
        "user": {
            "id": db_user["id"],
            "name": db_user["name"],
            "email": db_user["email"],
            "phone": db_user["phone"],
            "role": db_user["role"],
            "approved": db_user.get("approved", False),
        },
    }


class ChangeEmailRequest(BaseModel):
    new_email: EmailStr
    password: str

@router.post("/change-email")
def change_email(data: ChangeEmailRequest, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT password_hash FROM users WHERE id = %s", (user["id"],))
    row = cursor.fetchone()
    if not row or not bcrypt.verify(data.password, row["password_hash"]):
        cursor.close()
        conn.close()
        raise HTTPException(status_code=401, detail="Incorrect password")

    cursor.execute("SELECT id FROM users WHERE email = %s AND id != %s", (data.new_email, user["id"]))
    if cursor.fetchone():
        cursor.close()
        conn.close()
        raise HTTPException(status_code=400, detail="Email already in use")

    cursor.execute("UPDATE users SET email = %s WHERE id = %s", (data.new_email, user["id"]))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Email updated successfully"}


class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

@router.post("/change-password")
def change_password(data: ChangePasswordRequest, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT password_hash FROM users WHERE id = %s", (user["id"],))
    row = cursor.fetchone()

    if not row or not bcrypt.verify(data.old_password, row["password_hash"]):
        cursor.close()
        conn.close()
        raise HTTPException(status_code=401, detail="Old password is incorrect")

    new_hash = bcrypt.hash(data.new_password)
    cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (new_hash, user["id"]))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Password changed successfully"}


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


@router.post("/forgot-password", status_code=status.HTTP_200_OK)
def forgot_password(data: ForgotPasswordRequest):
    user = get_user_by_email(data.email)

    if not user:
        # Don't reveal whether email exists
        return {"message": "If the account exists, a reset code will be sent."}

    conn = get_connection()
    cursor = get_cursor(conn)

    # Delete old codes for this user
    cursor.execute("DELETE FROM password_reset_codes WHERE user_id = %s", (user["id"],))

    # Generate 6-digit code
    code = ''.join(random.choices(string.digits, k=6))
    expires_at = datetime.now() + timedelta(minutes=15)

    cursor.execute(
        "INSERT INTO password_reset_codes (user_id, code, expires_at) VALUES (%s, %s, %s)",
        (user["id"], code, expires_at)
    )
    conn.commit()
    cursor.close()
    conn.close()

    # Send the code via email
    send_reset_email(data.email, code)
    return {"message": "If the account exists, a reset code will be sent."}


class VerifyResetCode(BaseModel):
    email: EmailStr
    code: str

@router.post("/verify-reset-code")
def verify_reset_code(data: VerifyResetCode):
    user = get_user_by_email(data.email)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid code")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute(
        "SELECT id FROM password_reset_codes WHERE user_id = %s AND code = %s AND expires_at > NOW()",
        (user["id"], data.code.strip())
    )
    row = cursor.fetchone()
    cursor.close()
    conn.close()

    if not row:
        raise HTTPException(status_code=401, detail="Invalid or expired code")

    return {"message": "Code verified", "reset_id": row["id"]}


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str

@router.post("/reset-password")
def reset_password(data: ResetPasswordRequest):
    user = get_user_by_email(data.email)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid request")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute(
        "SELECT id FROM password_reset_codes WHERE user_id = %s AND code = %s AND expires_at > NOW()",
        (user["id"], data.code.strip())
    )
    row = cursor.fetchone()
    if not row:
        cursor.close(); conn.close()
        raise HTTPException(status_code=401, detail="Invalid or expired code")

    # Update password
    new_hash = bcrypt.hash(data.new_password)
    cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (new_hash, user["id"]))

    # Delete used code
    cursor.execute("DELETE FROM password_reset_codes WHERE user_id = %s", (user["id"],))

    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Password reset successfully"}


@router.post("/generate-parent-code")
def generate_parent_code(user=Depends(get_current_user)):
    if user["role"] != "athlete":
        raise HTTPException(status_code=403, detail="Only athletes can generate parent codes")

    conn = get_connection()
    cursor = get_cursor(conn)

    # Delete any existing codes for this user
    cursor.execute("DELETE FROM parent_access_codes WHERE user_id = %s", (user["id"],))

    # Generate a unique 6-character uppercase code
    for _ in range(10):
        code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        cursor.execute("SELECT 1 FROM parent_access_codes WHERE code = %s", (code,))
        if not cursor.fetchone():
            break

    expires_at = datetime.now() + timedelta(hours=72)
    cursor.execute(
        "INSERT INTO parent_access_codes (user_id, code, expires_at) VALUES (%s, %s, %s)",
        (user["id"], code, expires_at)
    )
    conn.commit()
    cursor.close()
    conn.close()
    return {"code": code, "expires_at": expires_at.isoformat()}


class ParentCodeLogin(BaseModel):
    code: str

@router.post("/login-with-code")
def login_with_code(data: ParentCodeLogin):
    conn = get_connection()
    cursor = get_cursor(conn)

    code = data.code.strip().upper()
    cursor.execute(
        "SELECT * FROM parent_access_codes WHERE code = %s AND expires_at > NOW()",
        (code,)
    )
    row = cursor.fetchone()
    if not row:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=401, detail="Invalid or expired code")

    cursor.execute("SELECT * FROM users WHERE id = %s", (row["user_id"],))
    db_user = cursor.fetchone()
    if not db_user:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    token = jwt.encode(
        {"sub": str(db_user["id"])},
        settings.JWT_SECRET,
        algorithm=settings.JWT_ALGORITHM,
    )

    cursor.close()
    conn.close()

    return {
        "token": token,
        "user": {
            "id": db_user["id"],
            "name": db_user["name"],
            "email": db_user["email"],
            "phone": db_user["phone"],
            "role": db_user["role"],
            "approved": db_user.get("approved", False),
        },
    }
