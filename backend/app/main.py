from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app import auth, users, branches, gear, threads, payments, notifications, attendance
from app.middleware.logging import LoggingMiddleware
from app import athlete
from app import performance  # ⬅️ Make sure this import is there
from app import measurements
from app import coach
from app import head_coach






app = FastAPI()

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

@app.get("/")
def root():
    return {"message": "HFA API is running"}