# FILE: app/headcoach.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.database import get_connection
from app.deps import get_current_user

router = APIRouter()

class CoachAssignmentInput(BaseModel):
    coach_id: int
    branch_id: int

def verify_head_coach(user):
    if user["role"] != "head_coach":
        raise HTTPException(status_code=403, detail="Only head coaches can manage assignments")

@router.get("/headcoach/branches")
def get_all_branches(user=Depends(get_current_user)):
    verify_head_coach(user)
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT id, name FROM branches ORDER BY name")
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result

@router.get("/headcoach/coaches")
def get_all_coaches(user=Depends(get_current_user)):
    verify_head_coach(user)
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT id, name FROM users 
        WHERE role = 'coach'
        ORDER BY name
    """)
    coaches = cursor.fetchall()
    cursor.close()
    conn.close()
    return coaches

@router.get("/headcoach/assignments")
def get_assignments(user=Depends(get_current_user)):
    verify_head_coach(user)
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT ca.id, ca.branch_id, ca.coach_id, u.name AS coach_name
        FROM coach_assignments ca
        JOIN users u ON ca.coach_id = u.id
    """)
    data = cursor.fetchall()
    cursor.close()
    conn.close()
    return data

@router.post("/headcoach/assign")
def assign_coach(data: CoachAssignmentInput, user=Depends(get_current_user)):
    verify_head_coach(user)
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT IGNORE INTO coach_assignments (branch_id, coach_id)
        VALUES (%s, %s)
    """, (data.branch_id, data.coach_id))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Coach assigned to branch."}

@router.post("/headcoach/unassign")
def unassign_coach(data: CoachAssignmentInput, user=Depends(get_current_user)):
    verify_head_coach(user)
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        DELETE FROM coach_assignments 
        WHERE branch_id = %s AND coach_id = %s
    """, (data.branch_id, data.coach_id))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Coach unassigned from branch."}