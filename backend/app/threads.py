from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.database import get_connection, get_cursor
from app.deps import get_current_user
from app.utils.auth_utils import can_access_branch
from app.utils.push import send_push_to_users

router = APIRouter()

class ThreadCreate(BaseModel):
    title: str

class MessageCreate(BaseModel):
    message: str

@router.get("/branch/{branch_id}")
def get_branch_threads(branch_id: int, user=Depends(get_current_user)):
    can_access_branch(user, branch_id)

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("""
            SELECT * FROM threads
            WHERE branch_id = %s AND title != 'gear'
            ORDER BY created_at ASC
        """, (branch_id,))
        threads = [dict(r) for r in cursor.fetchall()]

        if not threads:
            cursor.execute("SELECT name FROM branches WHERE id = %s", (branch_id,))
            branch = cursor.fetchone()
            branch_name = branch["name"] if branch else f"Branch {branch_id}"

            cursor.execute("""
                INSERT INTO threads (branch_id, title, created_at)
                VALUES (%s, %s, NOW())
            """, (branch_id, f"Branch: {branch_name} General"))
            conn.commit()

            cursor.execute("""
                SELECT * FROM threads
                WHERE branch_id = %s AND title != 'gear'
                ORDER BY created_at ASC
            """, (branch_id,))
            threads = [dict(r) for r in cursor.fetchall()]

        return threads

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    finally:
        cursor.close()
        conn.close()

@router.post("/branch/{branch_id}/ensure-thread")
def ensure_branch_thread(branch_id: int, user=Depends(get_current_user)):
    can_access_branch(user, branch_id)

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("""
            SELECT id FROM threads
            WHERE branch_id = %s AND title != 'gear'
            LIMIT 1
        """, (branch_id,))
        existing = cursor.fetchone()

        if not existing:
            cursor.execute("SELECT name FROM branches WHERE id = %s", (branch_id,))
            branch = cursor.fetchone()
            branch_name = branch["name"] if branch else f"Branch {branch_id}"

            cursor.execute("""
                INSERT INTO threads (branch_id, title, created_at)
                VALUES (%s, %s, NOW()) RETURNING id
            """, (branch_id, f"Branch: {branch_name} General"))
            thread_id = cursor.fetchone()["id"]
            conn.commit()
        else:
            thread_id = existing["id"]

        return {"thread_id": thread_id, "message": "Thread ready"}

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    finally:
        cursor.close()
        conn.close()

@router.get("/{thread_id}/posts")
def get_posts(thread_id: int, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        # Verify the thread belongs to the user's branch
        cursor.execute("SELECT branch_id FROM threads WHERE id = %s", (thread_id,))
        thread = cursor.fetchone()
        if not thread:
            raise HTTPException(status_code=404, detail="Thread not found")

        can_access_branch(user, thread["branch_id"])

        cursor.execute("""
            SELECT p.id, p.message, p.user_id, u.name AS author, p.created_at
            FROM posts p
            JOIN users u ON p.user_id = u.id
            WHERE p.thread_id = %s
            ORDER BY p.created_at ASC
        """, (thread_id,))
        posts = [dict(r) for r in cursor.fetchall()]
        return posts

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    finally:
        cursor.close()
        conn.close()

@router.post("/branch/{branch_id}/create")
def create_thread(branch_id: int, data: ThreadCreate, user=Depends(get_current_user)):
    can_access_branch(user, branch_id)

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("""
            INSERT INTO threads (branch_id, title, created_at)
            VALUES (%s, %s, NOW()) RETURNING id
        """, (branch_id, data.title))
        thread_id = cursor.fetchone()["id"]
        conn.commit()

        return {"message": "Thread created", "thread_id": thread_id}

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create thread: {str(e)}")
    finally:
        cursor.close()
        conn.close()

@router.post("/{thread_id}/post")
def post_message(thread_id: int, data: MessageCreate, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can post to threads")

    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("SELECT branch_id FROM threads WHERE id = %s", (thread_id,))
        thread = cursor.fetchone()

        if not thread:
            raise HTTPException(status_code=404, detail="Thread not found")

        # Verify the coach can post to this branch's thread
        can_access_branch(user, thread["branch_id"])

        cursor.execute("""
            INSERT INTO posts (thread_id, user_id, message, created_at)
            VALUES (%s, %s, %s, NOW())
        """, (thread_id, user["id"], data.message))

        # Notify all athletes in this branch
        branch_id = thread["branch_id"]
        cursor.execute("""
            SELECT u.id FROM users u
            JOIN athletes a ON a.user_id = u.id
            WHERE u.branch_id = %s AND u.approved = TRUE AND u.id != %s
        """, (branch_id, user["id"]))
        athlete_user_ids = [row["id"] for row in cursor.fetchall()]

        # Notify other coaches assigned to this branch (a coach can be assigned to multiple branches)
        cursor.execute("""
            SELECT DISTINCT ca.user_id FROM coach_assignments ca
            WHERE ca.branch_id = %s AND ca.user_id != %s
        """, (branch_id, user["id"]))
        coach_user_ids = [row["user_id"] for row in cursor.fetchall()]

        cursor.execute("SELECT name FROM branches WHERE id = %s", (branch_id,))
        branch_row = cursor.fetchone()
        branch_name = branch_row["name"] if branch_row else f"Branch {branch_id}"

        sender_name = user.get("name", "Coach")
        preview = data.message[:80] + ("..." if len(data.message) > 80 else "")
        notif_msg = f"{sender_name}: {preview}"
        for uid in athlete_user_ids + coach_user_ids:
            cursor.execute(
                "INSERT INTO notifications (user_id, message, type) VALUES (%s, %s, 'thread')",
                (uid, notif_msg)
            )

        conn.commit()

        # Send push notifications (after commit so DB is consistent)
        push_body = f"{sender_name}\n{data.message}"
        send_push_to_users(
            cursor, athlete_user_ids + coach_user_ids, branch_name, push_body,
            data={"type": "thread"},
        )

        return {"message": "Post added", "success": True}

    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to post message: {str(e)}")
    finally:
        cursor.close()
        conn.close()
