from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.database import get_connection, get_cursor
from app.deps import get_current_user

router = APIRouter()

BRANCH_FIELDS = "id, name, address, phone, whatsapp, video_url, practice_days"


class BranchPayload(BaseModel):
    name: str
    address: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    video_url: Optional[str] = None
    practice_days: Optional[str] = None


def _require_head_coach(user):
    if user["role"] != "head_coach":
        raise HTTPException(status_code=403, detail="Only the head coach can manage branches")


@router.get("/")
def list_branches():
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute(f"SELECT {BRANCH_FIELDS} FROM branches ORDER BY name")
    branches = [dict(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return branches


@router.get("/{branch_id}")
def get_branch(branch_id: int):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute(f"SELECT {BRANCH_FIELDS} FROM branches WHERE id = %s", (branch_id,))
    branch = cursor.fetchone()
    cursor.close()
    conn.close()
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found")
    return dict(branch)


@router.post("/")
def create_branch(data: BranchPayload, user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)
    try:
        cursor.execute(
            """
            INSERT INTO branches (name, address, phone, whatsapp, video_url, practice_days)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING """ + BRANCH_FIELDS,
            (data.name, data.address, data.phone, data.whatsapp, data.video_url, data.practice_days),
        )
        branch = dict(cursor.fetchone())
        conn.commit()
        return branch
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create branch: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.put("/{branch_id}")
def update_branch(branch_id: int, data: BranchPayload, user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)
    try:
        cursor.execute(
            """
            UPDATE branches
            SET name = %s, address = %s, phone = %s, whatsapp = %s, video_url = %s, practice_days = %s
            WHERE id = %s
            RETURNING """ + BRANCH_FIELDS,
            (data.name, data.address, data.phone, data.whatsapp, data.video_url, data.practice_days, branch_id),
        )
        branch = cursor.fetchone()
        if not branch:
            raise HTTPException(status_code=404, detail="Branch not found")
        conn.commit()
        return dict(branch)
    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update branch: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.delete("/{branch_id}")
def delete_branch(branch_id: int, user=Depends(get_current_user)):
    _require_head_coach(user)
    conn = get_connection()
    cursor = get_cursor(conn)
    try:
        cursor.execute("SELECT COUNT(*) AS c FROM users WHERE branch_id = %s", (branch_id,))
        if cursor.fetchone()["c"] > 0:
            raise HTTPException(
                status_code=409,
                detail="Branch has members assigned to it. Move or remove them before deleting.",
            )

        # Clean up branch-scoped data that has no members behind it
        cursor.execute("DELETE FROM posts WHERE thread_id IN (SELECT id FROM threads WHERE branch_id = %s)", (branch_id,))
        cursor.execute("DELETE FROM threads WHERE branch_id = %s", (branch_id,))
        cursor.execute("DELETE FROM coach_assignments WHERE branch_id = %s", (branch_id,))

        cursor.execute("DELETE FROM branches WHERE id = %s RETURNING id", (branch_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Branch not found")
        conn.commit()
        return {"message": "Branch deleted"}
    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete branch: {str(e)}")
    finally:
        cursor.close()
        conn.close()
