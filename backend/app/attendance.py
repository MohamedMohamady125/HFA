from fastapi import APIRouter, Depends, HTTPException
from fastapi.concurrency import run_in_threadpool
from app.deps import get_current_user
from app.database import get_connection, get_cursor
from app.utils.auth_utils import can_access_branch
from pydantic import BaseModel
from datetime import date, timedelta
import traceback

router = APIRouter()

WEEKDAY_MAP = {
    "Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6,
}

def get_branch_session_dates(practice_days_str: str) -> list[str]:
    today = date.today()
    offset = (today.weekday() - 4) % 7
    last_friday = today - timedelta(days=offset)

    extracted_days = []
    for entry in practice_days_str.split(","):
        parts = entry.strip().split(":")
        if parts:
            weekday_part = parts[0].strip()
            for key in WEEKDAY_MAP:
                if key.lower() in weekday_part.lower():
                    extracted_days.append(key)
                    break

    session_dates = []
    for day in extracted_days[:3]:
        weekday_num = WEEKDAY_MAP[day]
        delta = (weekday_num - 4) % 7
        session_date = last_friday + timedelta(days=delta)
        session_dates.append(session_date.isoformat())

    return session_dates

class AttendanceMark(BaseModel):
    athlete_id: int
    session_date: str
    status: str

def _fetch_attendance_sync(branch_id: int, session_date: str, user_id: int):
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("""SELECT a.id as athlete_id, u.name as athlete_name
                      FROM athletes a
                      JOIN users u ON a.user_id = u.id
                      WHERE u.branch_id = %s ORDER BY u.name""", (branch_id,))
    athletes = cursor.fetchall()

    cursor.execute("SELECT athlete_id, status FROM attendance WHERE session_date = %s AND branch_id = %s", (session_date, branch_id))
    existing = cursor.fetchall()
    existing_map = {x["athlete_id"]: x["status"] for x in existing}

    to_seed = [(a["athlete_id"], session_date, branch_id, user_id) for a in athletes if a["athlete_id"] not in existing_map]
    if to_seed:
        for record in to_seed:
            cursor.execute("""INSERT INTO attendance (athlete_id, session_date, status, branch_id, recorded_by)
                              VALUES (%s, %s, NULL, %s, %s)
                              ON CONFLICT (athlete_id, session_date) DO NOTHING""", record)

    cursor.execute("""SELECT a.id AS athlete_id, u.name AS athlete_name, att.status
                      FROM athletes a
                      JOIN users u ON a.user_id = u.id
                      LEFT JOIN attendance att ON att.athlete_id = a.id AND att.session_date = %s AND att.branch_id = %s
                      WHERE u.branch_id = %s ORDER BY u.name""",
                   (session_date, branch_id, branch_id))
    result = [dict(r) for r in cursor.fetchall()]
    conn.commit()
    cursor.close()
    conn.close()
    return result

@router.get("/branch/{branch_id}/session-dates")
def get_branch_session_dates_api(branch_id: int, user=Depends(get_current_user)):
    can_access_branch(user, branch_id)

    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT practice_days FROM branches WHERE id = %s", (branch_id,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()

    if not row or not row["practice_days"]:
        raise HTTPException(status_code=404, detail="Practice days not set")

    return get_branch_session_dates(row["practice_days"])

@router.get("/branch/{branch_id}/day/{session_date}")
async def get_attendance_by_day(branch_id: int, session_date: str, user=Depends(get_current_user)):
    can_access_branch(user, branch_id)
    return await run_in_threadpool(_fetch_attendance_sync, branch_id, session_date, user["id"])

def _mark_attendance_sync(data: AttendanceMark, user: dict):
    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("""SELECT u.branch_id FROM athletes a JOIN users u ON a.user_id = u.id WHERE a.id = %s""", (data.athlete_id,))
    res = cursor.fetchone()
    if not res:
        raise HTTPException(status_code=404, detail="Athlete not found")
    if user["role"] != "head_coach" and int(res["branch_id"]) != int(user["branch_id"]):
        raise HTTPException(status_code=403, detail="You can only mark attendance for athletes in your branch")

    cursor.execute("""INSERT INTO attendance (athlete_id, session_date, status, branch_id, recorded_by)
                      VALUES (%s, %s, %s, %s, %s)
                      ON CONFLICT (athlete_id, session_date) DO UPDATE SET status = EXCLUDED.status, recorded_by = EXCLUDED.recorded_by""",
                   (data.athlete_id, data.session_date, data.status, user["branch_id"], user["id"]))

    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Attendance updated successfully"}

@router.post("/mark")
async def mark_attendance(data: AttendanceMark, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can mark attendance")
    return await run_in_threadpool(_mark_attendance_sync, data, user)

@router.get("/athlete/{user_id}/week")
def get_athlete_weekly_attendance(user_id: int, user=Depends(get_current_user)):
    if user["id"] != user_id and user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Access denied")

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("""
            SELECT a.id AS athlete_id, u.branch_id
            FROM athletes a
            JOIN users u ON a.user_id = u.id
            WHERE u.id = %s
        """, (user_id,))
        result = cursor.fetchone()

        if not result:
            raise HTTPException(status_code=404, detail="Athlete profile not found")

        athlete_id = result["athlete_id"]
        branch_id = result["branch_id"]

        if user["role"] in ["coach"] and user["id"] != user_id:
            if user["branch_id"] != branch_id:
                raise HTTPException(status_code=403, detail="Cannot access athletes from other branches")

        cursor.execute("SELECT practice_days FROM branches WHERE id = %s", (branch_id,))
        branch = cursor.fetchone()

        if not branch or not branch["practice_days"]:
            raise HTTPException(status_code=400, detail="Branch has no practice days configured")

        session_dates = get_branch_session_dates(branch["practice_days"])

        records = []
        for i, session_date in enumerate(session_dates):
            cursor.execute("""
                SELECT status
                FROM attendance
                WHERE athlete_id = %s AND session_date = %s AND branch_id = %s
            """, (athlete_id, session_date, branch_id))
            row = cursor.fetchone()
            records.append({"day_number": i + 1, "status": row["status"] if row else None})

        return records

    finally:
        cursor.close()
        conn.close()

@router.get("/athlete/{user_id}/history")
def get_athlete_attendance_history(user_id: int, user=Depends(get_current_user)):
    if user["id"] != user_id and user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Access denied")

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("""
            SELECT a.id AS athlete_id, u.branch_id
            FROM athletes a
            JOIN users u ON a.user_id = u.id
            WHERE u.id = %s
        """, (user_id,))
        result = cursor.fetchone()
        if not result:
            raise HTTPException(status_code=404, detail="Athlete not found")

        athlete_id = result["athlete_id"]
        branch_id = result["branch_id"]

        if user["role"] == "coach" and user["id"] != user_id:
            if user["branch_id"] != branch_id:
                raise HTTPException(status_code=403, detail="Cannot access athletes from other branches")

        cursor.execute("""
            SELECT session_date, status
            FROM attendance
            WHERE athlete_id = %s AND branch_id = %s AND status IS NOT NULL
            ORDER BY session_date
        """, (athlete_id, branch_id))
        rows = cursor.fetchall()

        return [{"date": r["session_date"].isoformat(), "status": r["status"]} for r in rows]

    finally:
        cursor.close()
        conn.close()


@router.get("/athlete/{user_id}/month/{year}/{month}")
def get_athlete_monthly_attendance(user_id: int, year: int, month: int, user=Depends(get_current_user)):
    if user["id"] != user_id and user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Access denied")

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("""
            SELECT a.id AS athlete_id, u.branch_id
            FROM athletes a
            JOIN users u ON a.user_id = u.id
            WHERE u.id = %s
        """, (user_id,))
        result = cursor.fetchone()
        if not result:
            raise HTTPException(status_code=404, detail="Athlete not found")

        athlete_id = result["athlete_id"]
        branch_id = result["branch_id"]

        # Get all attendance records for this athlete in the given month
        cursor.execute("""
            SELECT session_date, status
            FROM attendance
            WHERE athlete_id = %s AND branch_id = %s
              AND EXTRACT(YEAR FROM session_date) = %s
              AND EXTRACT(MONTH FROM session_date) = %s
            ORDER BY session_date
        """, (athlete_id, branch_id, year, month))

        rows = [{"date": r["session_date"].isoformat(), "status": r["status"]} for r in cursor.fetchall()]
        return rows

    finally:
        cursor.close()
        conn.close()

@router.get("/branch/{branch_id}/athletes-stats")
def get_branch_athletes_stats(branch_id: int, user=Depends(get_current_user)):
    can_access_branch(user, branch_id)
    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("""
            SELECT a.id AS athlete_id, u.id AS user_id, u.name AS athlete_name
            FROM athletes a
            JOIN users u ON a.user_id = u.id
            WHERE u.branch_id = %s AND u.role = 'athlete' AND u.approved = true
            ORDER BY u.name
        """, (branch_id,))
        athletes = [dict(r) for r in cursor.fetchall()]

        for ath in athletes:
            cursor.execute("""
                SELECT
                    COUNT(*) FILTER (WHERE status = 'present') AS present,
                    COUNT(*) FILTER (WHERE status = 'absent') AS absent,
                    COUNT(*) AS total
                FROM attendance
                WHERE athlete_id = %s AND branch_id = %s
            """, (ath['athlete_id'], branch_id))
            stats = cursor.fetchone()
            ath['present'] = stats['present'] or 0
            ath['absent'] = stats['absent'] or 0
            ath['total'] = stats['total'] or 0
            ath['rate'] = round((ath['present'] / ath['total'] * 100)) if ath['total'] > 0 else 0

        return athletes
    finally:
        cursor.close()
        conn.close()

@router.get("/branch/{branch_id}/summary")
def get_attendance_summary(branch_id: int, user=Depends(get_current_user)):
    can_access_branch(user, branch_id)

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("SELECT practice_days FROM branches WHERE id = %s", (branch_id,))
        branch = cursor.fetchone()
        if not branch or not branch["practice_days"]:
            raise HTTPException(status_code=404, detail="Practice days not set")

        session_dates = get_branch_session_dates(branch["practice_days"])

        query = """
            SELECT
                a.id AS athlete_id,
                u.name AS athlete_name,
                at.session_date,
                at.status
            FROM athletes a
            JOIN users u ON a.user_id = u.id
            LEFT JOIN attendance at
              ON at.athlete_id = a.id AND at.branch_id = %s AND at.session_date IN (%s, %s, %s)
            WHERE u.branch_id = %s
            ORDER BY u.name, at.session_date
        """
        cursor.execute(query, (branch_id, *session_dates, branch_id))
        rows = [dict(r) for r in cursor.fetchall()]

        return {
            "records": rows,
            "session_dates": session_dates
        }

    finally:
        cursor.close()
        conn.close()
