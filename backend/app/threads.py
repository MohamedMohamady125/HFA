from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.database import get_connection
from app.deps import get_current_user
from app.utils.auth_utils import can_access_branch

router = APIRouter()

class ThreadCreate(BaseModel):
    title: str

class MessageCreate(BaseModel):
    message: str

@router.get("/branch/{branch_id}")
def get_branch_threads(branch_id: int):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM threads WHERE branch_id = %s AND title != 'gear'", (branch_id,))
    return cursor.fetchall()

@router.get("/{thread_id}/posts")
def get_posts(thread_id: int):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT p.id, p.message, u.name AS author, p.created_at
        FROM posts p
        JOIN users u ON p.user_id = u.id
        WHERE p.thread_id = %s
        ORDER BY p.created_at DESC
    """, (thread_id,))
    return cursor.fetchall()

@router.post("/branch/{branch_id}/create")
def create_thread(branch_id: int, data: ThreadCreate, user=Depends(get_current_user)):
    can_access_branch(user, branch_id)

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO threads (branch_id, title) VALUES (%s, %s)", (branch_id, data.title))
    conn.commit()
    return {"message": "Thread created"}

@router.post("/{thread_id}/post")
def post_message(thread_id: int, data: MessageCreate, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can post to threads")

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO posts (thread_id, user_id, message) VALUES (%s, %s, %s)",
        (thread_id, user["id"], data.message)
    )
    conn.commit()
    return {"message": "Post added"}
