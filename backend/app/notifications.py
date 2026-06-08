from fastapi import APIRouter, Depends, HTTPException
from app.database import get_connection, get_cursor
from app.deps import get_current_user

router = APIRouter()

@router.get("/")
def get_notifications(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT * FROM notifications WHERE user_id = %s ORDER BY created_at DESC", (user["id"],))
    rows = [dict(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return rows

@router.post("/")
def send_notification(user_id: int, message: str, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can send notifications")

    conn = get_connection()
    cursor = get_cursor(conn)

    # Verify target user belongs to the coach's branch
    cursor.execute("SELECT branch_id FROM users WHERE id = %s", (user_id,))
    target = cursor.fetchone()
    if not target:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Target user not found")

    if user["role"] != "head_coach" and int(target["branch_id"]) != int(user["branch_id"]):
        cursor.close()
        conn.close()
        raise HTTPException(status_code=403, detail="You can only send notifications to users in your branch")

    cursor.execute("INSERT INTO notifications (user_id, message) VALUES (%s, %s)", (user_id, message))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Notification sent"}

@router.get("/unread-count")
def get_unread_count(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute(
        "SELECT COUNT(*) as count FROM notifications WHERE user_id = %s AND read_status = FALSE",
        (user["id"],)
    )
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    return {"count": row["count"] if row else 0}


@router.post("/read/{notification_id}")
def mark_as_read(notification_id: int, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute(
        "UPDATE notifications SET read_status = TRUE WHERE id = %s AND user_id = %s",
        (notification_id, user["id"])
    )
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Notification marked as read"}


@router.post("/read-all")
def mark_all_as_read(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute(
        "UPDATE notifications SET read_status = TRUE WHERE user_id = %s AND read_status = FALSE",
        (user["id"],)
    )
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "All notifications marked as read"}
