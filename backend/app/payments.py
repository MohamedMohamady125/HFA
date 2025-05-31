from fastapi import APIRouter, Depends, HTTPException
from app.database import get_connection
from app.deps import get_current_user
from app.utils.auth_utils import can_access_branch
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()

class PaymentMark(BaseModel):
    athlete_id: int
    session_date: str
    status: str

@router.get("/summary/{branch_id}")
def get_payment_summary(branch_id: int, user=Depends(get_current_user)):
    can_access_branch(user, branch_id)
    conn = get_connection()
    cursor = conn.cursor(dictionary=True, buffered=True)

    cursor.execute("""
        SELECT a.id AS athlete_id, u.name AS athlete_name
        FROM athletes a
        JOIN users u ON a.user_id = u.id
        WHERE u.branch_id = %s AND u.role = 'athlete' AND u.approved = 1
        ORDER BY u.name
    """, (branch_id,))
    athletes = cursor.fetchall()

    cursor.execute("SELECT * FROM payments WHERE branch_id = %s", (branch_id,))
    payments = cursor.fetchall()

    session_dates = sorted({str(p["due_date"]) for p in payments})

    summary = []
    for athlete in athletes:
        athlete_id = athlete["athlete_id"]
        statuses = {date: "pending" for date in session_dates}
        for payment in payments:
            if payment["athlete_id"] == athlete_id:
                statuses[str(payment["due_date"])] = payment["status"]
        summary.append({
            "athlete_id": athlete_id,
            "athlete_name": athlete["athlete_name"],
            "statuses": statuses,
        })

    return {
        "records": summary,
        "session_dates": session_dates,
    }

@router.post("/mark")
def mark_payment(data: PaymentMark, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can update payments")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True, buffered=True)

    try:
        session_dt = datetime.strptime(data.session_date, "%Y-%m-%d").date()
        due_date = session_dt.replace(day=1)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")

    print(f"🔍 DEBUG - Marking payment:")
    print(f"   - athlete_id: {data.athlete_id}")
    print(f"   - session_date: {data.session_date}")
    print(f"   - session_dt: {session_dt}")
    print(f"   - due_date: {due_date}")
    print(f"   - status: {data.status}")
    print(f"   - branch_id: {user['branch_id']}")

    # Check athlete exists
    cursor.execute("SELECT * FROM athletes WHERE id = %s", (data.athlete_id,))
    athlete_check = cursor.fetchone()
    if not athlete_check:
        raise HTTPException(status_code=404, detail="Athlete not found")
    print(f"🔍 Athlete exists: {athlete_check}")

    # ✅ Delete any existing record for that month
    cursor.execute("""
        DELETE FROM payments 
        WHERE athlete_id = %s AND due_date = %s
    """, (data.athlete_id, due_date))

    # ✅ Insert the new payment record
    cursor.execute("""
        INSERT INTO payments (
            athlete_id, session_date, due_date, branch_id, status, confirmed_by_coach
        ) VALUES (%s, %s, %s, %s, %s, TRUE)
    """, (
        data.athlete_id,
        session_dt,
        due_date,
        user["branch_id"],
        data.status,
    ))

    conn.commit()

    print(f"✅ Payment recorded successfully for athlete {data.athlete_id} on {due_date}")
    return {
        "message": "Payment status updated",
        "debug": {
            "athlete_id": data.athlete_id,
            "due_date": str(due_date),
            "status": data.status
        }
    }

@router.get("/{athlete_id}/status")
def get_athlete_payment_status(athlete_id: int, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True, buffered=True)

    print(f"🔍 DEBUG - Getting payment status for user_id: {athlete_id}")

    cursor.execute("""
        SELECT id FROM athletes 
        WHERE user_id = %s
    """, (athlete_id,))
    athlete_record = cursor.fetchone()

    if not athlete_record:
        raise HTTPException(status_code=404, detail="Athlete not found")

    actual_athlete_id = athlete_record["id"]

    cursor.execute("""
        SELECT due_date, status, session_date, confirmed_by_coach FROM payments
        WHERE athlete_id = %s
        ORDER BY due_date DESC, id DESC
    """, (actual_athlete_id,))
    rows = cursor.fetchall()

    result = {}
    for row in rows:
        key = row["due_date"].strftime("%Y-%m-%d")
        result[key] = row["status"]  # always overwrite with latest record

    print(f"🔍 Final payment status result: {result}")
    return result