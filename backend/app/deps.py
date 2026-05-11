from fastapi import Depends, HTTPException, Header
from jose import jwt
from app.config import settings
from app.database import get_connection, get_cursor

# app/deps.py
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
    cursor.close()
    conn.close()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return dict(user)
