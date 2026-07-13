import json
import os
import logging

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


def _send_fcm_v1(token: str, title: str, body: str, access_token: str, project_id: str):
    """Send a single push notification via FCM HTTP v1 API directly."""
    import urllib.request

    url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
    payload = json.dumps({
        "message": {
            "token": token,
            "notification": {
                "title": title,
                "body": body,
            }
        }
    }).encode("utf-8")

    req = urllib.request.Request(url, data=payload, method="POST")
    req.add_header("Authorization", f"Bearer {access_token}")
    req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req) as resp:
            return {"success": True, "status": resp.status}
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8", errors="replace")
        return {"success": False, "status": e.code, "error": error_body}


# Arabic translations for push notification titles
_AR_TITLES = {
    "Gear for this week": "أدوات هذا الأسبوع",
    "Attendance": "الحضور",
}


def _localize_title(title: str, lang: str) -> str:
    if lang == "ar" and title in _AR_TITLES:
        return _AR_TITLES[title]
    return title


def _localize_body(body: str, lang: str, title: str) -> str:
    if lang != "ar":
        return body
    # Attendance messages
    if title == "Attendance" or title == _AR_TITLES.get("Attendance", ""):
        body = body.replace("You were marked present", "تم تسجيل حضورك")
        body = body.replace("You were marked absent", "تم تسجيل غيابك")
        body = body.replace(" for ", " في ")
    return body


def send_push_to_user(cursor, user_id: int, title: str, body: str):
    """Send push notification to all devices registered for a user."""
    try:
        access_token, project_id = _get_access_token()
        if not access_token:
            logger.warning("Could not get FCM access token — push disabled")
            return

        cursor.execute("SELECT token, lang FROM device_tokens WHERE user_id = %s", (user_id,))
        rows = cursor.fetchall()
        if not rows:
            return

        for row in rows:
            device_token = row["token"]
            lang = row.get("lang", "en") or "en"
            localized_title = _localize_title(title, lang)
            localized_body = _localize_body(body, lang, title)
            result = _send_fcm_v1(device_token, localized_title, localized_body, access_token, project_id)
            if not result["success"]:
                logger.error(f"FCM send failed for token {device_token[:20]}...: {result}")
                # Clean up invalid tokens
                error_str = result.get("error", "")
                if any(code in error_str for code in ["NOT_FOUND", "UNREGISTERED", "INVALID_ARGUMENT"]):
                    cursor.execute("DELETE FROM device_tokens WHERE token = %s", (device_token,))

    except Exception as e:
        logger.error(f"Push notification failed for user {user_id}: {e}")


def send_push_to_users(cursor, user_ids: list, title: str, body: str):
    """Send push notification to multiple users."""
    for uid in user_ids:
        send_push_to_user(cursor, uid, title, body)
