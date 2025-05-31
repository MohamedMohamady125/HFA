from fastapi import APIRouter, Depends
from app.deps import get_current_user
from app.database import get_connection

router = APIRouter()

@router.get("/athlete/home")
def get_athlete_dashboard(user=Depends(get_current_user)):
    if user["role"] != "athlete":
        return {"detail": "Access denied"}, 403

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        # Attendance (most recent)
        cursor.execute("""
            SELECT status, session_date
            FROM attendance
            WHERE athlete_id = (
                SELECT id FROM athletes WHERE user_id = %s
            )
            ORDER BY session_date DESC
            LIMIT 1
        """, (user["id"],))
        attendance = cursor.fetchone()

        # Gear
        cursor.execute("""
            SELECT p.message
            FROM posts p
            JOIN threads t ON p.thread_id = t.id
            WHERE t.branch_id = %s AND t.title = 'gear'
            ORDER BY p.created_at DESC
            LIMIT 1
        """, (user["branch_id"],))
        gear = cursor.fetchone()

        # Latest thread
        cursor.execute("""
            SELECT title FROM threads WHERE branch_id = %s
            ORDER BY id DESC LIMIT 1
        """, (user["branch_id"],))
        thread = cursor.fetchone()

        return {
            "attendance": attendance or {},
            "gear": gear["message"] if gear else None,
            "latest_thread": thread["title"] if thread else "No threads yet"
        }

    finally:
        cursor.close()
        conn.close()