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


def send_push_to_user(cursor, user_id: int, title: str, body: str):
    """Send push notification to all devices registered for a user."""
    if not _init_firebase():
        return

    try:
        from firebase_admin import messaging

        cursor.execute("SELECT token FROM device_tokens WHERE user_id = %s", (user_id,))
        tokens = [row["token"] for row in cursor.fetchall()]
        if not tokens:
            return

        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message)

        # Clean up invalid tokens
        for i, send_response in enumerate(response.responses):
            if send_response.exception:
                error_code = getattr(send_response.exception, 'code', '')
                if error_code in ('NOT_FOUND', 'UNREGISTERED', 'INVALID_ARGUMENT'):
                    cursor.execute("DELETE FROM device_tokens WHERE token = %s", (tokens[i],))

    except Exception as e:
        logger.error(f"Push notification failed for user {user_id}: {e}")


def send_push_to_users(cursor, user_ids: list, title: str, body: str):
    """Send push notification to multiple users."""
    for uid in user_ids:
        send_push_to_user(cursor, uid, title, body)
