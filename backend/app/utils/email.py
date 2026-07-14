import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
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

    msg = MIMEMultipart("alternative")
    msg["Subject"] = "HFA - Password Reset Code"
    msg["From"] = f"HFA Fitness Academy <{settings.FROM_EMAIL}>"
    msg["To"] = to_email
    msg.attach(MIMEText(html, "html"))

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(settings.FROM_EMAIL, settings.GMAIL_APP_PASSWORD)
        server.sendmail(settings.FROM_EMAIL, to_email, msg.as_string())

    print(f"Email sent to {to_email}")
