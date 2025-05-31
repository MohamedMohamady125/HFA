from fastapi import APIRouter, Depends, HTTPException
from app.database import get_connection
from app.deps import get_current_user
from passlib.hash import bcrypt
from datetime import date, datetime
import json
from pydantic import BaseModel

router = APIRouter()

class PaymentMark(BaseModel):
    athlete_id: int
    session_date: str  # actual training session
    status: str  # 'paid', 'pending', 'late'

@router.get("/me")
def get_current_user_details(user=Depends(get_current_user)):
    return {
        "id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "phone": user["phone"],
        "role": user["role"],
        "approved": bool(user.get("approved", False)),
        "branch_id": user.get("branch_id"),
    }

@router.get("/requests")
def get_registration_requests(user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can view registration requests")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT id, athlete_name, phone, email, submitted_at, approved
        FROM registration_requests
        WHERE approved = 0
        ORDER BY submitted_at DESC
    """)
    return cursor.fetchall()

@router.post("/approve/{request_id}")
def approve_registration_request(request_id: int, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can approve registrations")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    # Step 1: Fetch registration request
    cursor.execute("SELECT * FROM registration_requests WHERE id = %s", (request_id,))
    request = cursor.fetchone()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    # Step 2: Check if user already exists
    cursor.execute("SELECT * FROM users WHERE email = %s", (request["email"],))
    existing_user = cursor.fetchone()

    if existing_user:
        user_id = existing_user["id"]
        if existing_user["approved"]:
            return {"message": "User already approved"}

        cursor.execute("""
            UPDATE users
            SET approved = 1, branch_id = %s
            WHERE id = %s
        """, (user["branch_id"], user_id))
    else:
        cursor.execute("""
            INSERT INTO users (name, email, phone, password_hash, role, approved, branch_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            request["athlete_name"],
            request["email"],
            request["phone"],
            request["password_hash"],
            "athlete",
            True,
            user["branch_id"]
        ))
        user_id = cursor.lastrowid

    # Insert into athletes table if not already
    cursor.execute("INSERT IGNORE INTO athletes (user_id) VALUES (%s)", (user_id,))

    # Step 3: Add initial payment row for current month
    cursor.execute("SELECT id FROM athletes WHERE user_id = %s", (user_id,))
    athlete = cursor.fetchone()
    if athlete:
        athlete_id = athlete["id"]
        first_of_month = date.today().replace(day=1)

        cursor.execute("""
            INSERT INTO payments (athlete_id, session_date, due_date, branch_id, status, confirmed_by_coach)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE status = VALUES(status)
        """, (
            athlete_id,
            first_of_month,
            first_of_month,
            user["branch_id"],
            "pending",
            False
        ))

    # Step 4: Approve the request
    if not request["approved"]:
        cursor.execute("""
            UPDATE registration_requests
            SET approved = 1, approved_by = %s
            WHERE id = %s
        """, (user["id"], request_id))

    conn.commit()
    return {"message": "Registration approved"}

@router.post("/payments/mark")
def mark_payment(data: PaymentMark, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can update payments")

    conn = get_connection()
    cursor = conn.cursor()

    try:
        session_dt = datetime.strptime(data.session_date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid session_date format")

    due_date = session_dt.replace(day=1)

    cursor.execute("""
        INSERT INTO payments (athlete_id, session_date, due_date, branch_id, status, confirmed_by_coach)
        VALUES (%s, %s, %s, %s, %s, TRUE)
        ON DUPLICATE KEY UPDATE status = VALUES(status), confirmed_by_coach = TRUE
    """, (
        data.athlete_id,
        session_dt,
        due_date,
        user["branch_id"],
        data.status,
    ))

    conn.commit()
    return {"message": "Payment status updated"}

@router.post("/reject/{request_id}")
def reject_registration_request(request_id: int, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can reject registrations")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    # Step 1: Confirm the request exists
    cursor.execute("SELECT * FROM registration_requests WHERE id = %s", (request_id,))
    request = cursor.fetchone()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    # Step 2: Delete the request
    cursor.execute("DELETE FROM registration_requests WHERE id = %s", (request_id,))
    conn.commit()

    return {"message": "Registration request rejected successfully"}