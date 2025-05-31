from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.database import get_connection
from app.deps import get_current_user

router = APIRouter()

class PerformanceLogInput(BaseModel):
    meet_name: str
    meet_date: str
    event_name: str
    result_time: float  # Changed from str to float

@router.post("/athlete/performance-log")
def create_performance_log(data: PerformanceLogInput, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        # Get athlete ID from user
        cursor.execute("SELECT id FROM athletes WHERE user_id = %s", (user["id"],))
        athlete = cursor.fetchone()
        if not athlete:
            raise HTTPException(status_code=404, detail="Athlete not found")

        # Insert performance log
        cursor.execute("""
            INSERT INTO performance_logs (athlete_id, meet_name, meet_date, event_name, result_time)
            VALUES (%s, %s, %s, %s, %s)
        """, (
            athlete["id"], data.meet_name, data.meet_date, 
            data.event_name, data.result_time
        ))

        conn.commit()
        return {"message": "Performance log saved"}

    except Exception as e:
        print("❌ DB Insert Error:", e)
        raise HTTPException(status_code=500, detail="Failed to save performance log")
    finally:
        cursor.close()
        conn.close()

def seconds_to_time_string(seconds: float) -> str:
    """Convert seconds to readable time format"""
    try:
        if seconds >= 60:
            minutes = int(seconds // 60)
            remaining_seconds = seconds % 60
            return f"{minutes}:{remaining_seconds:05.2f}"
        else:
            return f"{seconds:.2f}"
    except (TypeError, ValueError):
        return str(seconds)  # Return as string if conversion fails

@router.get("/athlete/performance-logs")
def get_athlete_performance_logs(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        # Get athlete ID from user
        cursor.execute("SELECT id FROM athletes WHERE user_id = %s", (user["id"],))
        athlete = cursor.fetchone()
        if not athlete:
            raise HTTPException(status_code=404, detail="Athlete not found")

        # Get all performance logs for this athlete
        cursor.execute("""
            SELECT id, meet_name, meet_date, event_name, result_time
            FROM performance_logs
            WHERE athlete_id = %s
            ORDER BY id DESC
        """, (athlete["id"],))

        logs = cursor.fetchall()
        
        # Convert result_time back to readable format
        for log in logs:
            if log['result_time'] is not None:
                log['result_time'] = seconds_to_time_string(float(log['result_time']))
        
        return logs if logs else []  # Return empty array if no logs

    except Exception as e:
        print("❌ DB Query Error:", e)
        raise HTTPException(status_code=500, detail=f"Failed to fetch performance logs: {str(e)}")
    finally:
        cursor.close()
        conn.close()

@router.delete("/athlete/performance-logs")
def delete_all_athlete_performance_logs(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        # Get athlete ID from user
        cursor.execute("SELECT id FROM athletes WHERE user_id = %s", (user["id"],))
        athlete = cursor.fetchone()
        if not athlete:
            raise HTTPException(status_code=404, detail="Athlete not found")

        # Delete all performance logs for this athlete
        cursor.execute("""
            DELETE FROM performance_logs
            WHERE athlete_id = %s
        """, (athlete["id"],))

        conn.commit()
        deleted_count = cursor.rowcount
        return {"message": f"Deleted {deleted_count} performance logs"}

    except Exception as e:
        print("❌ DB Delete Error:", e)
        raise HTTPException(status_code=500, detail="Failed to delete performance logs")
    finally:
        cursor.close()
        conn.close()