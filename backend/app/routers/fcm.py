from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/users/me", tags=["fcm"])

class FCMTokenIn(BaseModel):
    token: str

# stockage in-memory pour la démo
TOKENS: set[str] = set()

@router.post("/fcm-token")
def update_my_fcm_token(payload: FCMTokenIn):
    TOKENS.add(payload.token)
    return {"ok": True, "tokens_count": len(TOKENS)}
