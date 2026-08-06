from app.database import get_connection, get_cursor

def get_user_by_email(email: str):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT id, email FROM users WHERE email = %s", (email,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return dict(result) if result else None


def delete_user_cascade(cursor, user_id: int, email: str):
    """Delete a user and ALL related data (does not commit)."""
    cursor.execute("DELETE FROM device_tokens WHERE user_id = %s", (user_id,))
    cursor.execute("DELETE FROM notifications WHERE user_id = %s", (user_id,))
    cursor.execute("DELETE FROM password_reset_codes WHERE user_id = %s", (user_id,))
    cursor.execute("DELETE FROM parent_access_codes WHERE user_id = %s", (user_id,))
    cursor.execute("DELETE FROM posts WHERE user_id = %s", (user_id,))

    cursor.execute("SELECT id FROM athletes WHERE user_id = %s", (user_id,))
    athlete = cursor.fetchone()
    if athlete:
        athlete_id = athlete["id"]
        cursor.execute("DELETE FROM payments WHERE athlete_id = %s", (athlete_id,))
        cursor.execute("DELETE FROM attendance WHERE athlete_id = %s", (athlete_id,))
        cursor.execute("DELETE FROM measurements WHERE athlete_id = %s", (athlete_id,))
        cursor.execute("DELETE FROM performance_logs WHERE athlete_id = %s", (athlete_id,))
        cursor.execute("DELETE FROM health_records WHERE athlete_id = %s", (athlete_id,))
        cursor.execute("DELETE FROM athletes WHERE id = %s", (athlete_id,))

    cursor.execute("DELETE FROM coach_assignments WHERE user_id = %s", (user_id,))
    cursor.execute("DELETE FROM registration_requests WHERE email = %s", (email,))
    cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
