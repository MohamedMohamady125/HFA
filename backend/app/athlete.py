from fastapi import APIRouter, Depends, HTTPException
from app.deps import get_current_user
from app.database import get_connection, get_cursor

router = APIRouter()

@router.get("/athlete/home")
def get_athlete_dashboard(user=Depends(get_current_user)):
    if user["role"] != "athlete":
        return {"detail": "Access denied"}, 403

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("""
            SELECT status, session_date
            FROM attendance
            WHERE athlete_id = (
                SELECT id FROM athletes WHERE user_id = %s
            ) AND branch_id = %s
            ORDER BY session_date DESC
            LIMIT 1
        """, (user["id"], user["branch_id"]))
        attendance = cursor.fetchone()

        cursor.execute("""
            SELECT p.message
            FROM posts p
            JOIN threads t ON p.thread_id = t.id
            WHERE t.branch_id = %s AND t.title = 'gear'
            ORDER BY p.created_at DESC
            LIMIT 1
        """, (user["branch_id"],))
        gear = cursor.fetchone()

        cursor.execute("""
            SELECT title FROM threads WHERE branch_id = %s
            ORDER BY id DESC LIMIT 1
        """, (user["branch_id"],))
        thread = cursor.fetchone()

        return {
            "attendance": dict(attendance) if attendance else {},
            "gear": gear["message"] if gear else None,
            "latest_thread": thread["title"] if thread else "No threads yet"
        }

    finally:
        cursor.close()
        conn.close()

@router.get("/athletes/branch/{branch_id}/full")
def get_branch_athletes_full(branch_id: int, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Access denied")

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("""
            SELECT a.id AS athlete_id, u.id AS user_id, u.name, u.email, u.phone
            FROM athletes a JOIN users u ON a.user_id = u.id
            WHERE u.branch_id = %s AND u.approved = true
            ORDER BY u.name
        """, (branch_id,))
        athletes = [dict(r) for r in cursor.fetchall()]

        for ath in athletes:
            # Attendance stats
            cursor.execute("""
                SELECT COUNT(*) FILTER (WHERE status='present') AS present,
                       COUNT(*) FILTER (WHERE status='absent') AS absent,
                       COUNT(*) AS total
                FROM attendance WHERE athlete_id=%s AND branch_id=%s
            """, (ath['athlete_id'], branch_id))
            s = cursor.fetchone()
            ath['present'] = s['present'] or 0
            ath['absent'] = s['absent'] or 0
            ath['total_sessions'] = s['total'] or 0
            ath['attendance_rate'] = round((ath['present'] / s['total'] * 100)) if s['total'] else 0

            # Measurements
            cursor.execute("""
                SELECT height, weight, arm, leg, fat, muscle
                FROM measurement_logs WHERE athlete_id=%s ORDER BY id DESC LIMIT 1
            """, (ath['athlete_id'],))
            m = cursor.fetchone()
            ath['measurements'] = dict(m) if m else None

            # Performance logs
            cursor.execute("""
                SELECT event_name, result_time FROM performance_logs
                WHERE athlete_id=%s ORDER BY id DESC
            """, (ath['athlete_id'],))
            ath['events'] = [dict(r) for r in cursor.fetchall()]

            # Payment status current month
            cursor.execute("""
                SELECT status FROM payments
                WHERE athlete_id=%s AND branch_id=%s
                ORDER BY due_date DESC LIMIT 1
            """, (ath['athlete_id'], branch_id))
            p = cursor.fetchone()
            ath['payment_status'] = p['status'] if p else 'none'

        return athletes
    finally:
        cursor.close()
        conn.close()

@router.get("/athletes/user/{user_id}")
def get_athlete_by_user(user_id: int, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)

    # Verify the requesting user can access this athlete
    cursor.execute("SELECT branch_id FROM users WHERE id = %s", (user_id,))
    target = cursor.fetchone()
    if not target:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    # Athletes can only look up themselves; coaches only their branch
    if user["role"] == "athlete" and user["id"] != user_id:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=403, detail="Access denied")
    if user["role"] == "coach" and int(target["branch_id"]) != int(user["branch_id"]):
        cursor.close()
        conn.close()
        raise HTTPException(status_code=403, detail="You can only access athletes in your branch")

    cursor.execute("SELECT id FROM athletes WHERE user_id = %s", (user_id,))
    athlete = cursor.fetchone()
    cursor.close()
    conn.close()
    if not athlete:
        raise HTTPException(status_code=404, detail="Athlete not found")
    return dict(athlete)
