from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from app.config import settings
from app.database import get_connection, get_cursor
from datetime import datetime, timedelta

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

def create_reset_token(user_id: int):
    expire = datetime.utcnow() + timedelta(hours=1)
    to_encode = {"sub": str(user_id), "exp": expire}
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    user = cursor.fetchone()
    cursor.close()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    return dict(user)
