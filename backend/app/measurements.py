from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.database import get_connection, get_cursor
from app.deps import get_current_user

router = APIRouter()

class MeasurementInput(BaseModel):
    height: float
    weight: float
    arm: float
    leg: float
    fat: float
    muscle: float

@router.post("/athlete/measurements")
def save_measurements(data: MeasurementInput, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("SELECT id FROM athletes WHERE user_id = %s", (user["id"],))
        athlete = cursor.fetchone()
        if not athlete:
            raise HTTPException(status_code=404, detail="Athlete not found")

        cursor.execute("""
            INSERT INTO measurement_logs (athlete_id, height, weight, arm, leg, fat, muscle)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            athlete["id"], data.height, data.weight,
            data.arm, data.leg, data.fat, data.muscle
        ))

        conn.commit()
        return {"message": "Measurements saved"}

    except Exception as e:
        print("DB Insert Error:", e)
        raise HTTPException(status_code=500, detail="Failed to save measurements")
    finally:
        cursor.close()
        conn.close()

@router.get("/athlete/measurements")
def get_latest_measurements(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)

    try:
        cursor.execute("SELECT id FROM athletes WHERE user_id = %s", (user["id"],))
        athlete = cursor.fetchone()
        if not athlete:
            raise HTTPException(status_code=404, detail="Athlete not found")

        cursor.execute("""
            SELECT height, weight, arm, leg, fat, muscle
            FROM measurement_logs
            WHERE athlete_id = %s
            ORDER BY id DESC
            LIMIT 1
        """, (athlete["id"],))

        data = cursor.fetchone()
        if not data:
            raise HTTPException(status_code=404, detail="No measurements found")

        return dict(data)

    finally:
        cursor.close()
        conn.close()
