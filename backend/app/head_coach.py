from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from app.database import get_connection, get_cursor
from app.deps import get_current_user
from passlib.hash import bcrypt
import secrets
import string

router = APIRouter()


def _require_head_coach(user):
    if user["role"] != "head_coach":
        raise HTTPException(status_code=403, detail="Access denied")


def _generate_password(length=10):
    chars = string.ascii_letters + string.digits
    return ''.join(secrets.choice(chars) for _ in range(length))


# ─── Branches ───────────────────────────────────────────────

@router.get("/branches")
def list_all_branches(user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT id, name, address, phone FROM branches ORDER BY name")
    branches = [dict(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return branches


@router.post("/select-branch/{branch_id}")
def select_branch(branch_id: int, user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT id FROM branches WHERE id = %s", (branch_id,))
    if not cursor.fetchone():
        raise HTTPException(status_code=404, detail="Branch not found")

    cursor.execute("UPDATE users SET branch_id = %s WHERE id = %s", (branch_id, user["id"]))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": f"Branch {branch_id} selected"}


# ─── Coach Management ───────────────────────────────────────

class CreateCoachRequest(BaseModel):
    name: str
    email: EmailStr
    phone: str = ""
    branch_id: int


class UpdateCoachRequest(BaseModel):
    name: str | None = None
    email: EmailStr | None = None
    phone: str | None = None
    branch_id: int | None = None


class ResetCoachPasswordRequest(BaseModel):
    new_password: str


@router.get("/coaches")
def list_coaches(user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("""
        SELECT u.id, u.name, u.email, u.phone, u.approved, u.branch_id,
               b.name AS branch_name,
               cc.plain_password
        FROM users u
        LEFT JOIN branches b ON u.branch_id = b.id
        LEFT JOIN coach_credentials cc ON cc.coach_user_id = u.id
        WHERE u.role = 'coach'
        ORDER BY u.name
    """)
    coaches = [dict(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return coaches


@router.post("/coaches")
def create_coach(data: CreateCoachRequest, user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT id FROM users WHERE email = %s", (data.email,))
    if cursor.fetchone():
        cursor.close()
        conn.close()
        raise HTTPException(status_code=400, detail="Email already in use")

    cursor.execute("SELECT id FROM branches WHERE id = %s", (data.branch_id,))
    if not cursor.fetchone():
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Branch not found")

    # Auto-generate password
    plain_password = _generate_password()
    password_hash = bcrypt.hash(plain_password)

    cursor.execute("""
        INSERT INTO users (name, email, phone, password_hash, role, approved, branch_id)
        VALUES (%s, %s, %s, %s, 'coach', TRUE, %s)
        RETURNING id
    """, (data.name, data.email, data.phone, password_hash, data.branch_id))
    new_id = cursor.fetchone()["id"]

    cursor.execute("""
        INSERT INTO coach_assignments (user_id, branch_id)
        VALUES (%s, %s)
        ON CONFLICT (user_id, branch_id) DO NOTHING
    """, (new_id, data.branch_id))

    # Store plain password for head coach reference
    cursor.execute("""
        INSERT INTO coach_credentials (coach_user_id, plain_password)
        VALUES (%s, %s)
    """, (new_id, plain_password))

    conn.commit()
    cursor.close()
    conn.close()
    return {
        "message": "Coach created",
        "id": new_id,
        "email": data.email,
        "password": plain_password,
    }


@router.put("/coaches/{coach_id}")
def update_coach(coach_id: int, data: UpdateCoachRequest, user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT id FROM users WHERE id = %s AND role = 'coach'", (coach_id,))
    if not cursor.fetchone():
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Coach not found")

    updates = []
    values = []
    if data.name is not None:
        updates.append("name = %s")
        values.append(data.name)
    if data.email is not None:
        cursor.execute("SELECT id FROM users WHERE email = %s AND id != %s", (data.email, coach_id))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Email already in use")
        updates.append("email = %s")
        values.append(data.email)
    if data.phone is not None:
        updates.append("phone = %s")
        values.append(data.phone)
    if data.branch_id is not None:
        cursor.execute("SELECT id FROM branches WHERE id = %s", (data.branch_id,))
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="Branch not found")
        updates.append("branch_id = %s")
        values.append(data.branch_id)

    if updates:
        values.append(coach_id)
        cursor.execute(f"UPDATE users SET {', '.join(updates)} WHERE id = %s", values)

        if data.branch_id is not None:
            cursor.execute("DELETE FROM coach_assignments WHERE user_id = %s", (coach_id,))
            cursor.execute("""
                INSERT INTO coach_assignments (user_id, branch_id)
                VALUES (%s, %s)
                ON CONFLICT (user_id, branch_id) DO NOTHING
            """, (coach_id, data.branch_id))

        conn.commit()

    cursor.close()
    conn.close()
    return {"message": "Coach updated"}


@router.post("/coaches/{coach_id}/reset-password")
def reset_coach_password(coach_id: int, data: ResetCoachPasswordRequest, user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT id FROM users WHERE id = %s AND role = 'coach'", (coach_id,))
    if not cursor.fetchone():
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Coach not found")

    new_hash = bcrypt.hash(data.new_password)
    cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (new_hash, coach_id))

    # Update stored credentials
    cursor.execute("""
        INSERT INTO coach_credentials (coach_user_id, plain_password)
        VALUES (%s, %s)
        ON CONFLICT (coach_user_id) DO UPDATE SET plain_password = EXCLUDED.plain_password
    """, (coach_id, data.new_password))

    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Password reset successfully", "password": data.new_password}


@router.delete("/coaches/{coach_id}")
def delete_coach(coach_id: int, user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT id FROM users WHERE id = %s AND role = 'coach'", (coach_id,))
    if not cursor.fetchone():
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Coach not found")

    cursor.execute("DELETE FROM coach_credentials WHERE coach_user_id = %s", (coach_id,))
    cursor.execute("DELETE FROM coach_assignments WHERE user_id = %s", (coach_id,))
    cursor.execute("DELETE FROM users WHERE id = %s AND role = 'coach'", (coach_id,))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Coach deleted"}
