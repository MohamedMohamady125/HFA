from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from app import auth, users, branches, gear, threads, payments, notifications, attendance
from app.middleware.logging import LoggingMiddleware
from app import athlete
from app import performance  # ⬅️ Make sure this import is there
from app import measurements
from app import coach
from app import head_coach
from app import admin_page






app = FastAPI()


@app.on_event("startup")
def run_migrations():
    from app.database import get_connection
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS parent_access_codes (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id),
                code VARCHAR(10) UNIQUE NOT NULL,
                expires_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            )
        """)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS device_tokens (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id),
                token TEXT NOT NULL,
                platform VARCHAR(20),
                lang VARCHAR(5) DEFAULT 'en',
                created_at TIMESTAMP DEFAULT NOW(),
                UNIQUE(user_id, token)
            )
        """)
        cursor.execute("""
            ALTER TABLE device_tokens ADD COLUMN IF NOT EXISTS lang VARCHAR(5) DEFAULT 'en'
        """)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS password_reset_codes (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id),
                code VARCHAR(10) NOT NULL,
                expires_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            )
        """)
        cursor.execute("ALTER TABLE branches ADD COLUMN IF NOT EXISTS whatsapp VARCHAR(50)")
        conn.commit()
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Migration warning: {e}")


# ✅ Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace with specific origin(s) in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Add custom logging middleware
app.add_middleware(LoggingMiddleware)



# ✅ Register routers

app.include_router(head_coach.router, prefix="/head-coach", tags=["head_coach"])
app.include_router(coach.router)
app.include_router(measurements.router)
app.include_router(performance.router, tags=["performance"])  # ⬅️ Register the router
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(branches.router, prefix="/branches", tags=["branches"])
app.include_router(gear.router, prefix="/gear", tags=["gear"])
app.include_router(threads.router, prefix="/threads", tags=["threads"])
app.include_router(payments.router, prefix="/payments", tags=["payments"])
app.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
app.include_router(attendance.router, prefix="/attendance", tags=["attendance"])
app.include_router(athlete.router, tags=["athlete"])
app.include_router(admin_page.router, tags=["admin"])

@app.get("/")
def root():
    return {"message": "HFA API is running"}


@app.get("/privacy-policy", response_class=HTMLResponse)
def privacy_policy():
    return """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy – HFA Fitness</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; color: #333; }
        h1 { color: #1a1a1a; border-bottom: 2px solid #eee; padding-bottom: 10px; }
        h2 { color: #2c2c2c; margin-top: 30px; }
        ul { padding-left: 20px; }
        li { margin-bottom: 6px; }
        .updated { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>Privacy Policy</h1>
    <p class="updated">Last updated: June 23, 2026</p>
    <p>HFA Fitness ("we", "our", or "us") operates the HFA Fitness mobile application. This Privacy Policy explains how we collect, use, and protect your personal information.</p>

    <h2>1. Information We Collect</h2>
    <p>We collect the following types of information when you use our app:</p>
    <h3>Account Information</h3>
    <ul>
        <li>Full name, email address, and phone number</li>
        <li>Account credentials (passwords are stored securely using encryption)</li>
        <li>User role (athlete, coach, or head coach)</li>
        <li>Branch or location affiliation</li>
    </ul>
    <h3>Health and Fitness Data</h3>
    <ul>
        <li>Body measurements (height, weight, arm and leg circumference, body fat percentage, muscle percentage)</li>
        <li>Athletic performance records (meet name, date, event, and result times)</li>
        <li>Health history records (titles, notes, and attached files)</li>
    </ul>
    <h3>Activity Data</h3>
    <ul>
        <li>Session attendance records</li>
        <li>Coach notes and feedback</li>
        <li>Forum posts and messages</li>
    </ul>
    <h3>Payment Information</h3>
    <ul>
        <li>Payment status and session dates for tracking purposes</li>
        <li>We do not collect or store credit card numbers or bank account details</li>
    </ul>
    <h3>Device Information</h3>
    <ul>
        <li>Device tokens for push notifications (Firebase Cloud Messaging for Android, Apple Push Notification service for iOS)</li>
        <li>Device platform type</li>
    </ul>

    <h2>2. How We Use Your Information</h2>
    <ul>
        <li>To provide and maintain our fitness coaching services</li>
        <li>To track your athletic performance and body measurements over time</li>
        <li>To facilitate communication between athletes and coaches</li>
        <li>To send push notifications about training updates, gear announcements, and other relevant information</li>
        <li>To manage attendance and payment records</li>
        <li>To authenticate your identity and secure your account</li>
    </ul>

    <h2>3. Data Sharing</h2>
    <p>We do not sell your personal information to third parties. Your data may be shared in the following limited circumstances:</p>
    <ul>
        <li><strong>Within the app:</strong> Coaches and head coaches can view athlete data relevant to training (measurements, performance, attendance)</li>
        <li><strong>Service providers:</strong> We use Firebase Cloud Messaging (Google) and Apple Push Notification service to deliver push notifications</li>
        <li><strong>Legal requirements:</strong> We may disclose your information if required to do so by law</li>
    </ul>

    <h2>4. Data Security</h2>
    <p>We implement appropriate security measures to protect your personal information, including:</p>
    <ul>
        <li>Password encryption using industry-standard hashing algorithms</li>
        <li>Secure HTTPS connections for all data transmission</li>
        <li>Token-based authentication for API access</li>
    </ul>

    <h2>5. Data Retention</h2>
    <p>We retain your personal data for as long as your account is active or as needed to provide you services. You may request deletion of your account and associated data by contacting us.</p>

    <h2>6. Children's Privacy</h2>
    <p>Our app may be used by minors under parental or guardian supervision. We provide parent access codes to allow guardians to monitor their child's account. We do not knowingly collect data from children under 13 without parental consent.</p>

    <h2>7. Your Rights</h2>
    <p>You have the right to:</p>
    <ul>
        <li>Access the personal data we hold about you</li>
        <li>Request correction of inaccurate data</li>
        <li>Request deletion of your data</li>
        <li>Withdraw consent for data processing</li>
    </ul>

    <h2>8. Changes to This Policy</h2>
    <p>We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.</p>

    <h2>9. Contact Us</h2>
    <p>If you have questions about this Privacy Policy or wish to exercise your data rights, please contact us at:</p>
    <p>Email: <a href="mailto:mohamadhany97@gmail.com">mohamadhany97@gmail.com</a></p>
</body>
</html>"""


@app.get("/delete-account", response_class=HTMLResponse)
def delete_account():
    return """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Delete Account – HFA Fitness</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; line-height: 1.6; color: #333; }
        h1 { color: #1a1a1a; border-bottom: 2px solid #eee; padding-bottom: 10px; }
        h2 { color: #2c2c2c; margin-top: 30px; }
        ul { padding-left: 20px; }
        li { margin-bottom: 6px; }
        .warning { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>Delete Your Account</h1>
    <p>If you would like to delete your HFA Fitness account and all associated data, please follow the steps below.</p>

    <h2>How to Request Account Deletion</h2>
    <p>Send an email to <a href="mailto:mohamadhany97@gmail.com?subject=Account%20Deletion%20Request">mohamadhany97@gmail.com</a> with the following details:</p>
    <ul>
        <li>Subject line: <strong>Account Deletion Request</strong></li>
        <li>Your registered email address</li>
        <li>Your full name as it appears in the app</li>
    </ul>

    <h2>What Gets Deleted</h2>
    <p>Upon processing your request, the following data will be permanently deleted:</p>
    <ul>
        <li>Your account information (name, email, phone number)</li>
        <li>Body measurements and performance records</li>
        <li>Health history records</li>
        <li>Attendance records</li>
        <li>Payment records</li>
        <li>Forum posts and messages</li>
        <li>Device tokens and notification history</li>
    </ul>

    <div class="warning">
        <strong>Please note:</strong> Account deletion is permanent and cannot be undone. All your data will be removed within 30 days of your request.
    </div>

    <h2>Contact</h2>
    <p>If you have questions, contact us at <a href="mailto:mohamadhany97@gmail.com">mohamadhany97@gmail.com</a></p>
</body>
</html>"""