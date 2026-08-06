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


@app.get("/terms-of-service", response_class=HTMLResponse)
def terms_of_service():
    return """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terms of Service – HFA Fitness</title>
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
    <h1>Terms of Service</h1>
    <p class="updated">Last updated: July 14, 2026</p>
    <p>Welcome to HFA Fitness. By downloading, installing, or using the HFA Fitness mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.</p>

    <h2>1. Eligibility</h2>
    <p>You must be at least 13 years of age to create an account. Users under 18 must have a parent or guardian's consent. Parents may monitor their child's account using the parent access code feature provided within the App.</p>

    <h2>2. Account Registration</h2>
    <p>To use the App, you must register with accurate and complete information including your name, email address, and phone number. You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account.</p>

    <h2>3. Acceptable Use</h2>
    <p>You agree to use the App only for its intended purpose — managing fitness training, tracking athletic performance, and communicating with coaches. You agree not to:</p>
    <ul>
        <li>Use the App for any unlawful purpose</li>
        <li>Share your account credentials with others</li>
        <li>Upload harmful, offensive, or inappropriate content</li>
        <li>Attempt to gain unauthorized access to other users' accounts or data</li>
        <li>Interfere with or disrupt the App's functionality</li>
    </ul>

    <h2>4. Health & Fitness Data</h2>
    <p>The App allows you to record health and fitness information including body measurements, performance records, and health history. This data is provided for informational and training purposes only and does not constitute medical advice. Always consult a qualified healthcare professional for medical decisions.</p>

    <h2>5. Coach and Athlete Relationship</h2>
    <p>The App facilitates communication between coaches and athletes. Coaches may view athlete data relevant to training including measurements, attendance, and performance records. Head coaches have additional administrative privileges including managing coaches and branches.</p>

    <h2>6. Push Notifications</h2>
    <p>The App may send push notifications regarding training updates, gear announcements, payment reminders, and other relevant information. You can manage notification preferences through your device settings.</p>

    <h2>7. Intellectual Property</h2>
    <p>All content, design, and functionality of the App are the property of HFA Fitness and are protected by intellectual property laws. You may not copy, modify, distribute, or create derivative works based on the App.</p>

    <h2>8. Account Termination</h2>
    <p>You may delete your account at any time through the App settings. We reserve the right to suspend or terminate accounts that violate these Terms. Upon termination, your data will be deleted in accordance with our Privacy Policy.</p>

    <h2>9. Disclaimer of Warranties</h2>
    <p>The App is provided "as is" without warranties of any kind, express or implied. We do not guarantee that the App will be available at all times or free from errors.</p>

    <h2>10. Limitation of Liability</h2>
    <p>To the fullest extent permitted by law, HFA Fitness shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App, including but not limited to injuries sustained during training activities.</p>

    <h2>11. Changes to These Terms</h2>
    <p>We may update these Terms from time to time. Continued use of the App after changes are posted constitutes acceptance of the modified Terms.</p>

    <h2>12. Governing Law</h2>
    <p>These Terms are governed by and construed in accordance with the laws of the Arab Republic of Egypt.</p>

    <h2>13. Contact Us</h2>
    <p>If you have questions about these Terms, please contact us at:</p>
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