from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr
from app.database import get_connection
from app.schemas import UserCreate, UserLogin
from passlib.hash import bcrypt
from jose import jwt
from app.config import settings
from app.utils.email import send_reset_email
from app.utils.tokens import create_reset_token
from app.utils.db_helpers import get_user_by_email  # ✅ avoids circular import

router = APIRouter()

# =========================
# ✅ Registration Endpoint
# =========================
@router.post("/register")
def register(user: UserCreate):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT id FROM registration_requests WHERE email = %s", (user.email,))
    if cursor.fetchone():
        raise HTTPException(status_code=400, detail="Email already submitted")

    # 🔍 Lookup branch name
    cursor.execute("SELECT name FROM branches WHERE id = %s", (user.branch_id,))
    branch = cursor.fetchone()
    if not branch:
        raise HTTPException(status_code=400, detail="Branch not found")

    branch_name = branch["name"]

    # 📝 Save registration request
    cursor.execute(
        "INSERT INTO registration_requests (athlete_name, phone, email, password_hash, branch_name) VALUES (%s, %s, %s, %s, %s)",
        (user.name, user.phone, user.email, bcrypt.hash(user.password), branch_name)
    )
    conn.commit()

    # 🔔 Notify the assigned coach
    cursor.execute("SELECT id FROM users WHERE role = 'coach' AND branch_id = %s LIMIT 1", (user.branch_id,))
    coach = cursor.fetchone()
    if coach:
        cursor.execute(
            "INSERT INTO notifications (user_id, message, type) VALUES (%s, %s, 'alert')",
            (coach["id"], f"New registration request for {branch_name}")
        )
        conn.commit()

    return {"message": "Request submitted. A coach will review and approve it."}


# =====================
# ✅ Login Endpoint
# =====================
@router.post("/login")
def login(user: UserLogin):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    print("🧪 Attempting login for:", user.email)

    cursor.execute("SELECT * FROM users WHERE email = %s", (user.email,))
    db_user = cursor.fetchone()

    if not db_user or not bcrypt.verify(user.password, db_user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # ✅ Auto-insert into athletes table if role is athlete and approved
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


# ===============================
# ✅ Forgot Password Endpoint
# ===============================
class ForgotPasswordRequest(BaseModel):
    email: EmailStr


@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(data: ForgotPasswordRequest):
    user = get_user_by_email(data.email)

    if not user:
        return {"detail": "If the account exists, a reset link will be sent."}

    token = create_reset_token(user["id"])
    send_reset_email(data.email, token)
    return {"detail": "Reset email sent"}