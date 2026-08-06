import json
import os
import logging
import threading

logger = logging.getLogger(__name__)

_fcm_initialized = False

def _init_firebase():
    global _fcm_initialized
    if _fcm_initialized:
        return True
    try:
        import firebase_admin
        from firebase_admin import credentials

        cred_json = os.getenv("FIREBASE_SERVICE_ACCOUNT")
        if not cred_json:
            logger.warning("FIREBASE_SERVICE_ACCOUNT not set — push notifications disabled")
            return False

        # Parse the JSON — handle Railway potentially mangling newlines
        try:
            cred_dict = json.loads(cred_json)
        except json.JSONDecodeError:
            cred_json_fixed = cred_json.replace('\n', '\\n').replace('\\\\n', '\\n')
            cred_dict = json.loads(cred_json_fixed)

        # Ensure private key has proper newlines (Railway may double-escape them)
        pk = cred_dict.get("private_key", "")
        if "\\n" in pk and "\n" not in pk:
            cred_dict["private_key"] = pk.replace("\\n", "\n")
        logger.info(f"Private key length: {len(cred_dict.get('private_key', ''))}, starts with BEGIN: {'BEGIN' in cred_dict.get('private_key', '')}")

        # Delete any existing Firebase app to ensure fresh credentials
        try:
            existing = firebase_admin.get_app()
            firebase_admin.delete_app(existing)
            logger.info("Deleted existing Firebase app for re-initialization")
        except ValueError:
            pass  # No existing app

        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
        _fcm_initialized = True
        logger.info("Firebase Admin SDK initialized for push notifications")
        return True
    except Exception as e:
        logger.error(f"Firebase init failed: {e}")
        return False


def force_reinit():
    """Force re-initialization of Firebase (useful after credential changes)."""
    global _fcm_initialized
    _fcm_initialized = False
    return _init_firebase()


def _get_access_token():
    """Get a fresh OAuth2 access token using the service account credentials."""
    from google.oauth2 import service_account
    import google.auth.transport.requests

    cred_json = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    if not cred_json:
        return None, None

    cred_dict = json.loads(cred_json)
    pk = cred_dict.get("private_key", "")
    if "\\n" in pk and "\n" not in pk:
        cred_dict["private_key"] = pk.replace("\\n", "\n")

    scopes = ["https://www.googleapis.com/auth/firebase.messaging"]
    credentials = service_account.Credentials.from_service_account_info(cred_dict, scopes=scopes)
    request = google.auth.transport.requests.Request()
    credentials.refresh(request)
    return credentials.token, cred_dict.get("project_id")


def _send_fcm_v1(token: str, title: str, body: str, access_token: str, project_id: str, data: dict = None):
    """Send a single push notification via FCM HTTP v1 API directly."""
    import urllib.request

    url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
    message = {
        "token": token,
        "notification": {
            "title": title,
            "body": body,
        },
        # iOS: play sound + vibrate + wake screen, delivered immediately
        "apns": {
            "headers": {"apns-priority": "10"},
            "payload": {"aps": {"sound": "default"}},
        },
        # Android: heads-up banner with sound/vibration via high-importance channel
        "android": {
            "priority": "HIGH",
            "notification": {
                "channel_id": "high_importance_channel",
                "default_sound": True,
                "default_vibrate_timings": True,
                "notification_priority": "PRIORITY_MAX",
            },
        },
    }
    if data:
        # FCM v1 requires all data values to be strings
        message["data"] = {k: str(v) for k, v in data.items()}
    payload = json.dumps({"message": message}).encode("utf-8")

    req = urllib.request.Request(url, data=payload, method="POST")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return {"success": True, "status": resp.status}
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8", errors="replace")
        return {"success": False, "status": e.code, "error": error_body}
    except Exception as e:
        return {"success": False, "status": None, "error": str(e)}


def _send_pushes_worker(user_ids: list, title: str, body: str,
                        title_ar: str = None, body_ar: str = None, data: dict = None):
    """Runs in a background thread: fetches token once, uses its own DB connection."""
    from app.database import get_connection, get_cursor

    conn = None
    try:
        access_token, project_id = _get_access_token()
        if not access_token:
            logger.warning("Could not get FCM access token — push disabled")
            return

        conn = get_connection()
        cursor = get_cursor(conn)
        cursor.execute(
            "SELECT user_id, token, lang FROM device_tokens WHERE user_id = ANY(%s)",
            (list(user_ids),)
        )
        rows = cursor.fetchall()

        invalid_tokens = []
        for row in rows:
            device_token = row["token"]
            lang = row.get("lang", "en") or "en"
            # Per-device localization: use the Arabic variant when provided
            localized_title = title_ar if (lang == "ar" and title_ar) else title
            localized_body = body_ar if (lang == "ar" and body_ar) else body
            result = _send_fcm_v1(device_token, localized_title, localized_body, access_token, project_id, data=data)
            if not result["success"]:
                logger.error(f"FCM send failed for token {device_token[:20]}...: {result}")
                error_str = result.get("error", "") or ""
                if any(code in error_str for code in ["NOT_FOUND", "UNREGISTERED", "INVALID_ARGUMENT"]):
                    invalid_tokens.append(device_token)

        # Clean up invalid tokens
        if invalid_tokens:
            cursor.execute("DELETE FROM device_tokens WHERE token = ANY(%s)", (invalid_tokens,))
            conn.commit()

        cursor.close()
    except Exception as e:
        logger.error(f"Push notification batch failed: {e}")
    finally:
        if conn:
            try:
                conn.close()
            except Exception:
                pass


def _send_tokens_worker(token_rows: list, title: str, body: str,
                        title_ar: str = None, body_ar: str = None, data: dict = None):
    """Send to explicit device tokens (no DB lookup) — used when the user's
    rows are deleted before the push can go out (e.g. registration rejection)."""
    try:
        access_token, project_id = _get_access_token()
        if not access_token:
            logger.warning("Could not get FCM access token — push disabled")
            return
        for row in token_rows:
            lang = row.get("lang", "en") or "en"
            localized_title = title_ar if (lang == "ar" and title_ar) else title
            localized_body = body_ar if (lang == "ar" and body_ar) else body
            result = _send_fcm_v1(row["token"], localized_title, localized_body, access_token, project_id, data=data)
            if not result["success"]:
                logger.error(f"FCM send failed for token {row['token'][:20]}...: {result}")
    except Exception as e:
        logger.error(f"Push to explicit tokens failed: {e}")


def send_push_to_tokens(token_rows: list, title: str, body: str,
                        title_ar: str = None, body_ar: str = None, data: dict = None):
    """Non-blocking push to explicit token rows [{'token': ..., 'lang': ...}]."""
    if not token_rows:
        return
    threading.Thread(
        target=_send_tokens_worker,
        args=([dict(r) for r in token_rows], title, body, title_ar, body_ar, data),
        daemon=True,
    ).start()


def send_push_to_user(cursor, user_id: int, title: str, body: str,
                      title_ar: str = None, body_ar: str = None, data: dict = None):
    """Send push notification to all devices registered for a user (non-blocking)."""
    send_push_to_users(cursor, [user_id], title, body, title_ar=title_ar, body_ar=body_ar, data=data)


def send_push_to_users(cursor, user_ids: list, title: str, body: str,
                       title_ar: str = None, body_ar: str = None, data: dict = None):
    """Send push notifications in a background thread so the request returns immediately.

    `title_ar`/`body_ar` are used for devices whose registered language is Arabic.
    `data` is attached to the FCM message so the app can deep-link on tap.
    The `cursor` argument is unused (kept for call-site compatibility); the worker
    opens its own DB connection since the request's cursor is closed after return.
    """
    if not user_ids:
        return
    threading.Thread(
        target=_send_pushes_worker,
        args=(list(user_ids), title, body, title_ar, body_ar, data),
        daemon=True,
    ).start()
