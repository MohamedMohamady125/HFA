from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.database import get_connection, get_cursor
from app.deps import get_current_user

router = APIRouter()

class GearPost(BaseModel):
    content: str

def get_assigned_branch_id(user: dict) -> int:
    if user["role"] in ["coach", "head_coach"]:
        conn = get_connection()
        cursor = get_cursor(conn)
        cursor.execute("SELECT branch_id FROM coach_assignments WHERE user_id = %s LIMIT 1", (user["id"],))
        assignment = cursor.fetchone()
        cursor.close()
        conn.close()
        if assignment:
            return assignment["branch_id"]
    elif user["role"] == "athlete":
        conn = get_connection()
        cursor = get_cursor(conn)
        cursor.execute("""
            SELECT u.branch_id FROM athletes a
            JOIN users u ON a.user_id = u.id
            WHERE u.id = %s
            LIMIT 1
        """, (user["id"],))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        if result and result.get("branch_id"):
            return result["branch_id"]
        return user.get("branch_id")
    return user.get("branch_id")

@router.get("/{branch_id}")
def get_gear(branch_id: int, user=Depends(get_current_user)):
    assigned_branch = get_assigned_branch_id(user)

    if user["role"] not in ["coach", "head_coach", "athlete"]:
        raise HTTPException(status_code=403, detail="Not authorized to view gear")
    if assigned_branch != branch_id:
        raise HTTPException(status_code=403, detail="You can only view gear for your assigned branch")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("""
        SELECT * FROM posts
        WHERE thread_id IN (
            SELECT id FROM threads WHERE branch_id = %s AND title = 'gear'
        )
        ORDER BY created_at DESC LIMIT 1
    """, (branch_id,))
    post = cursor.fetchone()
    cursor.close()
    conn.close()

    return dict(post) if post else {"message": "No gear updates posted yet"}

@router.post("/{branch_id}")
def post_gear(branch_id: int, data: GearPost, user=Depends(get_current_user)):
    assigned_branch = get_assigned_branch_id(user)
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can post gear")
    if assigned_branch != branch_id:
        raise HTTPException(status_code=403, detail="You can only post gear for your assigned branch")

    conn = get_connection()
    cursor = get_cursor(conn)

    cursor.execute("SELECT id FROM threads WHERE branch_id = %s AND title = 'gear'", (branch_id,))
    thread = cursor.fetchone()

    if not thread:
        cursor.execute("INSERT INTO threads (branch_id, title) VALUES (%s, %s) RETURNING id", (branch_id, "gear"))
        thread_id = cursor.fetchone()["id"]
        conn.commit()
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
