from fastapi import Depends, HTTPException, Header
from jose import jwt
from app.config import settings
from app.database import get_connection, get_cursor

def get_current_user(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid token")

    token = authorization[7:]
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id = payload.get("sub")
    except:
        raise HTTPException(status_code=401, detail="Could not validate token")

    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()
    if not user:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    user = dict(user)

    # Resolve branch_id from coach_assignments if not set on user
    if user["role"] in ["coach", "head_coach"] and not user.get("branch_id"):
        cursor.execute("SELECT branch_id FROM coach_assignments WHERE user_id = %s LIMIT 1", (user["id"],))
        assignment = cursor.fetchone()
        if assignment:
            user["branch_id"] = assignment["branch_id"]

    cursor.close()
    conn.close()
    return user
