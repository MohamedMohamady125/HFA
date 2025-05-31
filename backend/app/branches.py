from fastapi import APIRouter
from app.database import get_connection

router = APIRouter()

@router.get("/")
def list_branches():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT id, name, address, phone, video_url, practice_days 
        FROM branches
    """)
    branches = cursor.fetchall()
    return branches

@router.get("/{branch_id}")
def get_branch(branch_id: int):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM branches WHERE id = %s", (branch_id,))
    branch = cursor.fetchone()
    if not branch:
        return {"detail": "Branch not found"}
    return branch