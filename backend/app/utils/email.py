import sendgrid
from sendgrid.helpers.mail import Mail
from app.config import settings

def send_reset_email(to_email: str, token: str):
    reset_url = f"https://yourapp.com/reset-password?token={token}"

    message = Mail(
        from_email=settings.FROM_EMAIL,
        to_emails=to_email,
        subject="🔐 Reset Your HFA Password",
        html_content=f"""
        <p>Hi there,</p>
        <p>You requested to reset your password. Click the link below:</p>
        <a href="{reset_url}">Reset Password</a>
        <p>If you didn’t request this, you can ignore this email.</p>
        """
    )

    try:
        print(f"🔑 Using SendGrid API key: {settings.SENDGRID_API_KEY}")
        sg = sendgrid.SendGridAPIClient(api_key=settings.SENDGRID_API_KEY)
        response = sg.send(message)
        print(f"✅ Email sent to {to_email} | Status: {response.status_code}")
    except Exception as e:
        print(f"❌ Failed to send email: {e}")