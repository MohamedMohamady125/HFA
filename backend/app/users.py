from fastapi import APIRouter, Depends, HTTPException
from app.database import get_connection, get_cursor
from app.deps import get_current_user
from passlib.hash import bcrypt
from datetime import date, datetime
import json
from pydantic import BaseModel

router = APIRouter()

class PaymentMark(BaseModel):
    athlete_id: int
    session_date: str
    status: str

@router.get("/me")
def get_current_user_details(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)

    assigned_branch_id = user.get("branch_id")
    if user["role"] in ["coach", "head_coach"]:
        cursor.execute(
            "SELECT branch_id FROM coach_assignments WHERE user_id = %s LIMIT 1",
            (user["id"],),
        )
        assignment = cursor.fetchone()
        if assignment:
            assigned_branch_id = assignment["branch_id"]

    cursor.execute("SELECT name FROM branches WHERE id = %s", (assigned_branch_id,))
    branch = cursor.fetchone()
    branch_name = branch["name"] if branch else None

    cursor.close()
    conn.close()

    return {
        "id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "phone": user["phone"],
        "role": user["role"],
        "approved": bool(user.get("approved", False)),
        "branch_id": assigned_branch_id,
        "branch_name": branch_name,
    }

@router.get("/requests")
def get_registration_requests(user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can view registration requests")

    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("""
        SELECT id, athlete_name, phone, email, submitted_at, approved
        FROM registration_requests
        WHERE approved = false
        ORDER BY submitted_at DESC
    """)
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return [dict(r) for r in rows]

@router.post("/approve/{request_id}")
def approve_registration_request(request_id: int, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can approve registrations")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT * FROM registration_requests WHERE id = %s", (request_id,))
    request = cursor.fetchone()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    cursor.execute("SELECT * FROM users WHERE email = %s", (request["email"],))
    existing_user = cursor.fetchone()

    if existing_user:
        user_id = existing_user["id"]
        if existing_user["approved"]:
            return {"message": "User already approved"}

        cursor.execute("""
            UPDATE users
            SET approved = true, branch_id = %s
            WHERE id = %s
        """, (user["branch_id"], user_id))
    else:
        cursor.execute("""
            INSERT INTO users (name, email, phone, password_hash, role, approved, branch_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            request["athlete_name"],
            request["email"],
            request["phone"],
            request["password_hash"],
            "athlete",
            True,
            user["branch_id"]
        ))
        user_id = cursor.fetchone()["id"]

    # Insert athlete if not exists
    cursor.execute("INSERT INTO athletes (user_id) VALUES (%s) ON CONFLICT (user_id) DO NOTHING", (user_id,))

    # Add initial payment row for current month
    cursor.execute("SELECT id FROM athletes WHERE user_id = %s", (user_id,))
    athlete = cursor.fetchone()
    if athlete:
        athlete_id = athlete["id"]
        first_of_month = date.today().replace(day=1)

        cursor.execute("""
            INSERT INTO payments (athlete_id, session_date, due_date, branch_id, status, confirmed_by_coach)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (athlete_id, due_date) DO UPDATE SET status = EXCLUDED.status
        """, (
            athlete_id,
            first_of_month,
            first_of_month,
            user["branch_id"],
            "pending",
            False
        ))

    if not request["approved"]:
        cursor.execute("""
            UPDATE registration_requests
            SET approved = true, approved_by = %s
            WHERE id = %s
        """, (user["id"], request_id))

    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Registration approved"}

@router.post("/payments/mark")
def mark_payment(data: PaymentMark, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can update payments")

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        session_dt = datetime.strptime(data.session_date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid session_date format")

    due_date = session_dt.replace(day=1)

    cursor.execute("""
        INSERT INTO payments (athlete_id, session_date, due_date, branch_id, status, confirmed_by_coach)
        VALUES (%s, %s, %s, %s, %s, TRUE)
        ON CONFLICT (athlete_id, due_date) DO UPDATE SET status = EXCLUDED.status, confirmed_by_coach = TRUE
    """, (
        data.athlete_id,
        session_dt,
        due_date,
        user["branch_id"],
        data.status,
    ))

    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Payment status updated"}

@router.post("/reject/{request_id}")
def reject_registration_request(request_id: int, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can reject registrations")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT * FROM registration_requests WHERE id = %s", (request_id,))
    request = cursor.fetchone()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    cursor.execute("DELETE FROM registration_requests WHERE id = %s", (request_id,))
    conn.commit()
    cursor.close()
    conn.close()

    return {"message": "Registration request rejected successfully"}
