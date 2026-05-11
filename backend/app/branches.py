from fastapi import APIRouter
from app.database import get_connection, get_cursor

router = APIRouter()

@router.get("/")
def list_branches():
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("""
        SELECT id, name, address, phone, video_url, practice_days
        FROM branches
    """)
    branches = [dict(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return branches

@router.get("/{branch_id}")
def get_branch(branch_id: int):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT * FROM branches WHERE id = %s", (branch_id,))
    branch = cursor.fetchone()
    cursor.close()
    conn.close()
    if not branch:
        return {"detail": "Branch not found"}
    return dict(branch)
