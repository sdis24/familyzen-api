from fastapi import APIRouter, Depends, HTTPException, Response, status
from pydantic import BaseModel, constr
from sqlalchemy.orm import Session

try:
    from app.dependencies import get_db, get_current_user
    from app.models import User
except Exception:
    from ..dependencies import get_db, get_current_user
    from ..models import User

router = APIRouter(prefix="/users", tags=["Users"])

class FcmTokenIn(BaseModel):
    token: constr(min_length=10, max_length=4096)

@router.post("/me/fcm-token", status_code=status.HTTP_204_NO_CONTENT)
def update_my_fcm_token(
    data: FcmTokenIn,
    db: Session = Depends(get_db),
    current_user: "User" = Depends(get_current_user),
) -> Response:
    if not hasattr(current_user, "fcm_token"):
        raise HTTPException(status_code=500, detail="Champ 'fcm_token' absent du modèle User")
    current_user.fcm_token = data.token
    db.add(current_user)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)