from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.schemas import DashboardOut
from app.services.accounting import compute_dashboard

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])


@router.get("", response_model=DashboardOut)
async def dashboard(
    staff_id: Optional[str] = Query(default=None, description="Current staff ID"),
    db: AsyncSession = Depends(get_db),
):
    data = await compute_dashboard(db, staff_id or "")
    return DashboardOut(**data)
