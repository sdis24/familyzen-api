from datetime import datetime, timedelta, time
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Path
from pydantic import BaseModel

router = APIRouter(prefix="/families/{family_id}/assistant", tags=["assistant"])

class SuggestRequest(BaseModel):
    wake_up: Optional[str] = "07:00"      # HH:MM
    school_start: Optional[str] = "08:30" # HH:MM
    dinner: Optional[str] = "19:00"       # HH:MM
    chores: Optional[List[str]] = ["Set table", "Tidy room"]

def _today_at(hhmm: str) -> str:
    h, m = map(int, hhmm.split(":"))
    dt = datetime.combine(datetime.now().date(), time(h, m))
    return dt.isoformat()

@router.post("/suggest-plan")
def suggest_plan(family_id: int = Path(...), body: SuggestRequest = SuggestRequest()):
    plan: List[Dict[str, Any]] = [
        {"id": "wake",   "at": _today_at(body.wake_up),      "title": "Wake up",       "duration_min": 10},
        {"id": "break",  "at": _today_at(body.wake_up),      "title": "Breakfast",     "duration_min": 20},
        {"id": "school", "at": _today_at(body.school_start), "title": "Go to school",  "duration_min": 15},
        {"id": "study",  "at": (datetime.fromisoformat(_today_at(body.school_start)) + timedelta(hours=8)).isoformat(),
                         "title": "Homework", "duration_min": 45},
        {"id": "dinner", "at": _today_at(body.dinner),       "title": "Family dinner", "duration_min": 40},
    ]
    for i, c in enumerate(body.chores or []):
        plan.append({
            "id": f"chore_{i+1}",
            "at": (datetime.fromisoformat(_today_at(body.dinner)) + timedelta(minutes=45 + 10*i)).isoformat(),
            "title": c,
            "duration_min": 10,
        })
    return {
        "familyId": str(family_id),
        "received": body.model_dump(),
        "plan": plan,
        "meta": {"version": "demo-1"}
    }