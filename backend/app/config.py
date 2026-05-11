import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    DATABASE_URL = os.getenv("DATABASE_URL")
    JWT_SECRET = os.getenv("JWT_SECRET")
    JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

    SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY")
    FROM_EMAIL = os.getenv("FROM_EMAIL")

settings = Settings()