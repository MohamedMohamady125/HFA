from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.database import get_connection
from app.deps import get_current_user

router = APIRouter()

class GearPost(BaseModel):
    content: str

@router.get("/{branch_id}")
def get_gear(branch_id: int, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach", "athlete"]:
        raise HTTPException(status_code=403, detail="Not authorized to view gear")

    if str(user.get("branch_id")) != str(branch_id):
        raise HTTPException(status_code=403, detail="You can only view gear for your branch")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    # ✅ Join with threads to return title
    cursor.execute("""
        SELECT p.message, t.title as thread_title
        FROM posts p
        JOIN threads t ON p.thread_id = t.id
        WHERE t.branch_id = %s AND t.title = 'gear'
        ORDER BY p.created_at DESC LIMIT 1
    """, (branch_id,))

    post = cursor.fetchone()
    cursor.close()
    conn.close()

    return post or {"message": "No gear updates posted yet", "thread_title": "gear"}

@router.post("/{branch_id}")
def post_gear(branch_id: int, data: GearPost, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can post gear")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT id FROM threads WHERE branch_id = %s AND title = 'gear'", (branch_id,))
    thread = cursor.fetchone()

    if not thread:
        cursor.execute("INSERT INTO threads (branch_id, title) VALUES (%s, %s)", (branch_id, "gear"))
        thread_id = cursor.lastrowid
    else:
        thread_id = thread["id"]

    cursor.execute(
        "INSERT INTO posts (thread_id, user_id, message) VALUES (%s, %s, %s)",
        (thread_id, user["id"], data.content)
    )
    conn.commit()
    cursor.close()
    conn.close()

    return {"message": "Gear update posted"}
