from app.database import get_connection, get_cursor

def get_user_by_email(email: str):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT id, email FROM users WHERE email = %s", (email,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return dict(result) if result else None
