import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import health, fcm, assistant

app = FastAPI(title="FamilyZen API (starter)")

_origins = os.getenv("CORS_ALLOW_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _origins if o.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(fcm.router)
app.include_router(assistant.router)

@app.get("/")
def root():
    return {"ok": True, "service": "api"}

try:
    from app.routers import users
except Exception:
    from .routers import users
app.include_router(users.router)