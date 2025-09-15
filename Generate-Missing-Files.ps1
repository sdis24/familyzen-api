<#
.SYNOPSIS
    Génère les fichiers backend manquants (routes, CRUD, schémas) pour FamilyZen
    et met à jour app/main.py de façon idempotente.
.DESCRIPTION
    - Crée/écrit en UTF-8 SANS BOM pour éviter les problèmes d'encodage.
    - Ajoute les routes: /users/me/fcm-token et /families/{id}/assistant/suggest-plan (stub).
    - Ajoute CRUD et schémas de comportement (compat Pydantic v1/v2).
    - Met à jour app/main.py (imports + include_router) sans doublons.
#>
[CmdletBinding()]
param(
    # Dossier racine du projet (celui qui contient "backend/")
    [string]$ProjectRoot = ".\"
)

$ErrorActionPreference = "Stop"

function Write-NoBom {
    param([string]$Path, [string]$Content)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# --- Chemins ---
$BACKEND_DIR  = Join-Path $ProjectRoot "backend"
$APP_DIR      = Join-Path $BACKEND_DIR "app"
$ROUTERS_DIR  = Join-Path $APP_DIR "routers"
$CRUD_DIR     = Join-Path $APP_DIR "crud"

if (-not (Test-Path $APP_DIR)) {
    throw "Le dossier '$APP_DIR' est introuvable. Exécute ce script à la racine du dépôt (où se trouve 'backend/')."
}

# --- Création des dossiers ---
New-Item -ItemType Directory -Path $ROUTERS_DIR, $CRUD_DIR -Force -ErrorAction SilentlyContinue | Out-Null

# --- routers/users.py ---
$UsersRouter = @'
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
    """
    Enregistre ou met à jour le token FCM de l'utilisateur courant.
    """
    try:
        if not hasattr(current_user, "fcm_token"):
            raise HTTPException(status_code=500, detail="Champ 'fcm_token' absent du modèle User")
        current_user.fcm_token = data.token
        db.add(current_user)
        db.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"FCM token update failed: {exc}")
'@
Write-NoBom (Join-Path $ROUTERS_DIR "users.py") $UsersRouter

# --- routers/assistant.py ---
$AssistantRouter = @'
from fastapi import APIRouter

router = APIRouter(prefix="/families/{family_id}/assistant", tags=["Assistant"])

@router.post("/suggest-plan")
def suggest_plan(family_id: int):
    """
    MVP stub: renvoie une structure de plan vide pour débloquer le frontend.
    """
    return {
        "familyId": str(family_id),
        "received": None,
        "plan": [],
        "meta": {"version": "mvp-mock-1"}
    }
'@
Write-NoBom (Join-Path $ROUTERS_DIR "assistant.py") $AssistantRouter

# --- crud/behavior.py ---
$CrudBehavior = @'
from sqlalchemy.orm import Session
from datetime import datetime

from .. import models
from ..schemas_behavior import BehaviorNoteCreate, BehaviorReportCreate

def create_behavior_note(db: Session, data: BehaviorNoteCreate, family_id: int):
    note = models.BehaviorNote(
        family_id=family_id,
        user_id=data.user_id,
        kind=data.kind,
        text=data.text,
        created_at=datetime.utcnow(),
    )
    db.add(note)
    db.commit()
    db.refresh(note)
    return note

def list_behavior_notes(db: Session, family_id: int, limit: int = 100):
    return (
        db.query(models.BehaviorNote)
        .filter_by(family_id=family_id)
        .order_by(models.BehaviorNote.created_at.desc())
        .limit(limit).all()
    )

def create_behavior_report(db: Session, data: BehaviorReportCreate, family_id: int):
    rep = models.BehaviorReport(
        family_id=family_id,
        user_id=data.user_id,
        title=data.title,
        content=data.content,
        created_at=datetime.utcnow(),
    )
    db.add(rep)
    db.commit()
    db.refresh(rep)
    return rep

def list_behavior_reports(db: Session, family_id: int, limit: int = 100):
    return (
        db.query(models.BehaviorReport)
        .filter_by(family_id=family_id)
        .order_by(models.BehaviorReport.created_at.desc())
        .limit(limit).all()
    )
'@
Write-NoBom (Join-Path $CRUD_DIR "behavior.py") $CrudBehavior

# --- app/schemas_behavior.py (compat v1/v2) ---
$SchemasBehavior = @'
from datetime import datetime

try:
    # Pydantic v2
    from pydantic import BaseModel, Field, ConfigDict
    class ORMModel(BaseModel):
        model_config = ConfigDict(from_attributes=True)
except Exception:
    # Pydantic v1
    from pydantic import BaseModel, Field
    class ORMModel(BaseModel):
        class Config:
            orm_mode = True

class BehaviorNoteBase(BaseModel):
    kind: str = Field(description="positive|negative|neutral")
    text: str

class BehaviorNoteCreate(BehaviorNoteBase):
    user_id: int

class BehaviorNoteOut(ORMModel, BehaviorNoteBase):
    id: int
    family_id: int
    user_id: int
    created_at: datetime

class BehaviorReportBase(BaseModel):
    title: str
    content: str

class BehaviorReportCreate(BehaviorReportBase):
    user_id: int

class BehaviorReportOut(ORMModel, BehaviorReportBase):
    id: int
    family_id: int
    user_id: int
    created_at: datetime
'@
Write-NoBom (Join-Path $APP_DIR "schemas_behavior.py") $SchemasBehavior

# --- Mise à jour app/main.py ---
$MainPy = Join-Path $APP_DIR "main.py"
if (Test-Path $MainPy) {
    $content = Get-Content $MainPy -Raw

    # 1) Imports des routers
    if ($content -match 'from\s+app\.routers\s+import\s+([^\n]+)') {
        $existing = $Matches[1]
        $toAdd = @()
        if ($existing -notmatch '\busers\b') { $toAdd += 'users' }
        if ($existing -notmatch '\bassistant\b') { $toAdd += 'assistant' }
        if ($toAdd.Count -gt 0) {
            $newline = "from app.routers import $existing, $($toAdd -join ', ')"
            $content = ($content -replace "from\s+app\.routers\s+import\s+[^\n]+", $newline)
        }
    } elseif ($content -match 'from\s+\.\s*routers\s+import\s+([^\n]+)') {
        # style relatif
        $existing = $Matches[1]
        $toAdd = @()
        if ($existing -notmatch '\busers\b') { $toAdd += 'users' }
        if ($existing -notmatch '\bassistant\b') { $toAdd += 'assistant' }
        if ($toAdd.Count -gt 0) {
            $newline = "from .routers import $existing, $($toAdd -join ', ')"
            $content = ($content -replace "from\s+\.\s*routers\s+import\s+[^\n]+", $newline)
        }
    } else {
        # pas d'import existant -> en ajouter un en haut (après le premier import si possible)
        if ($content -match '^(from|import)\s+[^\n]+') {
            $content = $content -replace '^(from|import)\s+[^\n]+', "`$0`r`nfrom app.routers import users, assistant"
        } else {
            $content = "from app.routers import users, assistant`r`n" + $content
        }
    }

    # 2) include_router (ajout en fin si manquants)
    if ($content -notmatch 'app\.include_router\(\s*users\.router\s*\)') {
        $content += "`r`napp.include_router(users.router)"
    }
    if ($content -notmatch 'app\.include_router\(\s*assistant\.router\s*\)') {
        $content += "`r`napp.include_router(assistant.router)"
    }

    Write-NoBom $MainPy $content
} else {
    Write-Warning "app/main.py introuvable : imports et include_router à faire manuellement."
}

Write-Host "`n✅ Fichiers générés et main.py mis à jour. "
Write-Host "Prochaine étape : reconstruire et relancer Docker :"
Write-Host "    docker compose up --build -d"
