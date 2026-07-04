from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from typing import Optional
from app.deps import get_current_user
from app.database import get_connection, get_cursor
from passlib.hash import bcrypt

router = APIRouter()

class CoachProfile(BaseModel):
    name: str
    email: EmailStr
    branch: str

@router.get("/coach/profile", response_model=CoachProfile)
def get_coach_profile(user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can access this")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("""
        SELECT u.name, u.email, b.name AS branch
        FROM users u
        LEFT JOIN branches b ON u.branch_id = b.id
        WHERE u.id = %s
    """, (user["id"],))
    result = cursor.fetchone()

    cursor.close()
    conn.close()

    if not result:
        raise HTTPException(status_code=404, detail="Coach profile not found")
    return dict(result)

class UpdateCoachProfile(BaseModel):
    name: str
    email: EmailStr

@router.put("/coach/profile")
def update_coach_profile(data: UpdateCoachProfile, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can update profile")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("""
        UPDATE users SET name = %s, email = %s WHERE id = %s
    """, (data.name, data.email, user["id"]))
    conn.commit()

    cursor.close()
    conn.close()

    return {"message": "Profile updated successfully"}

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

@router.post("/coach/change-password")
def change_password(data: ChangePasswordRequest, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT password_hash FROM users WHERE id = %s", (user["id"],))
    row = cursor.fetchone()

    if not row or not bcrypt.verify(data.old_password, row["password_hash"]):
        raise HTTPException(status_code=401, detail="Old password is incorrect")

    new_hash = bcrypt.hash(data.new_password)

    cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (new_hash, user["id"]))
    conn.commit()

    cursor.close()
    conn.close()

    return {"message": "Password changed successfully"}


# ═══════════════════════════════════════════════════════
# COACH NOTES (bi-weekly, coach-only)
# ═══════════════════════════════════════════════════════

class CoachNoteCreate(BaseModel):
    athlete_id: int
    note: str
    period_label: Optional[str] = None

@router.post("/coach/notes")
def add_coach_note(data: CoachNoteCreate, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can add notes")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT id FROM athletes WHERE id = %s", (data.athlete_id,))
    if not cursor.fetchone():
        cursor.close(); conn.close()
        raise HTTPException(status_code=404, detail="Athlete not found")

    cursor.execute(
        "INSERT INTO coach_notes (athlete_id, coach_id, note, period_label) VALUES (%s, %s, %s, %s) RETURNING id",
        (data.athlete_id, user["id"], data.note, data.period_label)
    )
    note_id = cursor.fetchone()["id"]
    conn.commit()
    cursor.close()
    conn.close()
    return {"id": note_id, "message": "Note added"}


@router.get("/coach/notes/{athlete_id}")
def get_coach_notes(athlete_id: int, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can view notes")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("""
        SELECT cn.id, cn.note, cn.period_label, cn.created_at, u.name AS coach_name
        FROM coach_notes cn
        JOIN users u ON cn.coach_id = u.id
        WHERE cn.athlete_id = %s
        ORDER BY cn.created_at DESC
    """, (athlete_id,))
    notes = [dict(r) for r in cursor.fetchall()]
    for n in notes:
        n["created_at"] = n["created_at"].isoformat() if n["created_at"] else None

    cursor.close()
    conn.close()
    return notes


@router.delete("/coach/notes/{note_id}")
def delete_coach_note(note_id: int, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can delete notes")

    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("DELETE FROM coach_notes WHERE id = %s AND coach_id = %s", (note_id, user["id"]))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Note deleted"}
