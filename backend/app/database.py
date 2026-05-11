import psycopg2
import psycopg2.extras
from app.config import settings

def get_connection():
    conn = psycopg2.connect(settings.DATABASE_URL)
    return conn

def get_cursor(conn):
    """Returns a RealDictCursor for dictionary-style results."""
    return conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
