import httpx
from app.config import settings


def send_reset_email(to_email: str, code: str):
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px;">
        <h2 style="color: #1a1a2e; margin-bottom: 8px;">Reset Your Password</h2>
        <p style="color: #666; font-size: 15px;">Enter this code in the HFA app to reset your password:</p>
        <div style="background: #f0f4ff; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
            <span style="font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #1a1a2e;">{code}</span>
        </div>
        <p style="color: #999; font-size: 13px;">This code expires in 15 minutes.</p>
        <p style="color: #999; font-size: 13px;">If you didn't request this, ignore this email.</p>
    </div>
    """

    response = httpx.post(
        "https://api.resend.com/emails",
        headers={"Authorization": f"Bearer {settings.RESEND_API_KEY}"},
        json={
            "from": "HFA Fitness Academy <onboarding@resend.dev>",
            "reply_to": "thehfafitness@gmail.com",
            "to": [to_email],
            "subject": "HFA - Password Reset Code",
            "html": html,
        },
        timeout=10,
    )
    response.raise_for_status()
    print(f"[EMAIL] Sent to {to_email}", flush=True)
