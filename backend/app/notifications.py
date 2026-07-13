import json
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.database import get_connection, get_cursor
from app.deps import get_current_user

router = APIRouter()


class DeviceTokenRequest(BaseModel):
    token: str
    platform: str = "unknown"


@router.post("/register-device")
def register_device(data: DeviceTokenRequest, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("""
        INSERT INTO device_tokens (user_id, token, platform)
        VALUES (%s, %s, %s)
        ON CONFLICT (user_id, token) DO NOTHING
    """, (user["id"], data.token, data.platform))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Device registered"}

@router.get("/debug-device-tokens")
def debug_device_tokens(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT id, user_id, token, platform, created_at FROM device_tokens ORDER BY created_at DESC LIMIT 50")
    rows = [dict(r) for r in cursor.fetchall()]
    # Mask tokens for safety
    for r in rows:
        t = r.get("token", "")
        r["token"] = t[:20] + "..." if len(t) > 20 else t
    cursor.close()
    conn.close()
    return rows


@router.get("/")
def get_notifications(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT * FROM notifications WHERE user_id = %s ORDER BY created_at DESC", (user["id"],))
    rows = [dict(r) for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return rows

@router.post("/")
def send_notification(user_id: int, message: str, user=Depends(get_current_user)):
    if user["role"] not in ["coach", "head_coach"]:
        raise HTTPException(status_code=403, detail="Only coaches can send notifications")

    conn = get_connection()
    cursor = get_cursor(conn)

    # Verify target user belongs to the coach's branch
    cursor.execute("SELECT branch_id FROM users WHERE id = %s", (user_id,))
    target = cursor.fetchone()
    if not target:
        cursor.close()
        conn.close()
        raise HTTPException(status_code=404, detail="Target user not found")

    if user["role"] != "head_coach" and int(target["branch_id"]) != int(user["branch_id"]):
        cursor.close()
        conn.close()
        raise HTTPException(status_code=403, detail="You can only send notifications to users in your branch")

    cursor.execute("INSERT INTO notifications (user_id, message) VALUES (%s, %s)", (user_id, message))
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Notification sent"}

@router.post("/test-push")
def test_push(user=Depends(get_current_user)):
    """Debug endpoint: sends a test push to the current user and returns detailed results."""
    from app.utils.push import force_reinit
    import os

    results = {"steps": []}

    # Step 1: Check env var
    cred_json = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    # Check if JSON parses and private key looks right
    key_info = {}
    if cred_json:
        try:
            parsed = json.loads(cred_json)
            pk = parsed.get("private_key", "")
            key_info = {
                "json_valid": True,
                "has_private_key": bool(pk),
                "key_length": len(pk),
                "starts_with": pk[:30] if pk else "",
                "contains_real_newlines": '\n' in pk.replace('\\n', ''),
                "newline_count": pk.count('\n'),
                "escaped_newline_count": pk.count('\\n'),
            }
        except Exception as e:
            key_info = {"json_valid": False, "parse_error": str(e)}
    results["steps"].append({
        "step": "FIREBASE_SERVICE_ACCOUNT env var",
        "status": "set" if cred_json else "MISSING",
        "length": len(cred_json) if cred_json else 0,
        "key_info": key_info,
    })

    # Step 1b: Try getting an OAuth2 token directly to test credentials
    if cred_json:
        try:
            from google.oauth2 import service_account as sa
            import google.auth.transport.requests
            parsed_cred = json.loads(cred_json)
            pk = parsed_cred.get("private_key", "")
            if "\\n" in pk and "\n" not in pk:
                parsed_cred["private_key"] = pk.replace("\\n", "\n")
            scopes = ["https://www.googleapis.com/auth/firebase.messaging"]
            credentials_obj = sa.Credentials.from_service_account_info(parsed_cred, scopes=scopes)
            request = google.auth.transport.requests.Request()
            credentials_obj.refresh(request)
            results["steps"].append({
                "step": "OAuth2 token test",
                "status": "ok",
                "token_preview": str(credentials_obj.token)[:20] + "..." if credentials_obj.token else "none",
            })
        except Exception as e:
            results["steps"].append({
                "step": "OAuth2 token test",
                "status": "FAILED",
                "error": str(e),
                "error_type": type(e).__name__,
                "private_key_id": parsed_cred.get("private_key_id", "")[:10] + "...",
                "client_email": parsed_cred.get("client_email", ""),
            })

    # Step 2: Try Firebase init
    try:
        firebase_ok = force_reinit()
        results["steps"].append({"step": "Firebase init", "status": "ok" if firebase_ok else "FAILED"})
    except Exception as e:
        results["steps"].append({"step": "Firebase init", "status": "ERROR", "error": str(e)})

    # Step 3: Check device tokens for this user
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute("SELECT token, platform FROM device_tokens WHERE user_id = %s", (user["id"],))
    tokens = [dict(r) for r in cursor.fetchall()]
    results["steps"].append({"step": "Device tokens", "count": len(tokens), "tokens": [
        {"platform": t["platform"], "token_preview": t["token"][:30] + "..."} for t in tokens
    ]})

    # Step 4: Try sending
    if tokens and firebase_ok:
        try:
            from firebase_admin import messaging
            message = messaging.MulticastMessage(
                notification=messaging.Notification(title="HFA Test", body="Push notifications are working!"),
                tokens=[t["token"] for t in tokens],
            )
            response = messaging.send_each_for_multicast(message)
            send_results = []
            for i, send_response in enumerate(response.responses):
                if send_response.success:
                    send_results.append({"index": i, "status": "SUCCESS"})
                else:
                    err = send_response.exception
                    send_results.append({
                        "index": i,
                        "status": "FAILED",
                        "error": str(err),
                        "code": getattr(err, 'code', 'unknown'),
                    })
            results["steps"].append({"step": "Send push", "success_count": response.success_count, "failure_count": response.failure_count, "details": send_results})
        except Exception as e:
            results["steps"].append({"step": "Send push", "status": "ERROR", "error": str(e)})
    else:
        results["steps"].append({"step": "Send push", "status": "SKIPPED", "reason": "no tokens" if not tokens else "firebase not initialized"})

    cursor.close()
    conn.close()
    return results


@router.get("/unread-count")
def get_unread_count(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute(
        "SELECT COUNT(*) as count FROM notifications WHERE user_id = %s AND read_status = FALSE",
        (user["id"],)
    )
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    return {"count": row["count"] if row else 0}


@router.post("/read/{notification_id}")
def mark_as_read(notification_id: int, user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute(
        "UPDATE notifications SET read_status = TRUE WHERE id = %s AND user_id = %s",
        (notification_id, user["id"])
    )
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "Notification marked as read"}


@router.post("/read-all")
def mark_all_as_read(user=Depends(get_current_user)):
    conn = get_connection()
    cursor = get_cursor(conn)
    cursor.execute(
        "UPDATE notifications SET read_status = TRUE WHERE user_id = %s AND read_status = FALSE",
        (user["id"],)
    )
    conn.commit()
    cursor.close()
    conn.close()
    return {"message": "All notifications marked as read"}
