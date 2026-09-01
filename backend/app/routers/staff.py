import uuid
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models.staff import Staff
from app.schemas import StaffCreate, StaffUpdate, StaffOut, ApproveStaffRequest
from app.routers.auth import hash_secret, require_admin

router = APIRouter(prefix="/api/staff", tags=["staff"])


@router.get("", response_model=list[StaffOut])
async def list_staff(
    only_approved: bool = Query(True, description="Filter approved staff members only"),
    db: AsyncSession = Depends(get_db),
):
    q = select(Staff).where(Staff.is_active == True)
    if only_approved:
        q = q.where(Staff.is_approved == True)
    q = q.order_by(Staff.created_at)
    result = await db.execute(q)
    return result.scalars().all()


@router.get("/pending", response_model=list[StaffOut])
async def list_pending_staff(
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(require_admin),
):
    """
    List all pending staff member registration requests awaiting Admin approval.
    """
    result = await db.execute(
        select(Staff)
        .where(Staff.is_active == True, Staff.is_approved == False)
        .order_by(Staff.created_at.desc())
    )
    return result.scalars().all()


@router.post("/approve/{staff_id}", response_model=StaffOut)
@router.post("/{staff_id}/approve", response_model=StaffOut)
async def approve_staff(
    staff_id: str,
    body: Optional[ApproveStaffRequest] = None,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(require_admin),
):
    """
    Admin approves a pending staff registration request.
    """
    result = await db.execute(select(Staff).where(Staff.id == staff_id))
    staff = result.scalar_one_or_none()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff member not found")

    if body and body.verification_code and body.verification_code.strip():
        if staff.verification_code and staff.verification_code.strip() != body.verification_code.strip():
            raise HTTPException(status_code=400, detail="Invalid verification code provided.")

    staff.is_approved = True
    staff.verification_code = ""
    await db.commit()
    await db.refresh(staff)
    return staff


@router.post("/reject/{staff_id}")
@router.post("/{staff_id}/reject")
async def reject_staff(
    staff_id: str,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(require_admin),
):
    """
    Admin rejects/deletes a pending staff registration request.
    """
    result = await db.execute(select(Staff).where(Staff.id == staff_id))
    staff = result.scalar_one_or_none()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff member not found")

    await db.delete(staff)
    await db.commit()
    return {"message": f"Registration request for {staff.name} rejected."}


@router.post("", response_model=StaffOut)
async def create_staff(
    body: StaffCreate,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(require_admin),
):
    """
    Admin creates a new billing member directly.
    """
    result = await db.execute(select(Staff).where(Staff.is_active == True, Staff.is_approved == True))
    active = result.scalars().all()
    if len(active) >= 10:
        raise HTTPException(status_code=400, detail="Maximum limit of active billing members reached")

    pin_to_hash = body.pin or "1234"
    staff = Staff(
        id=str(uuid.uuid4()),
        name=body.name.strip(),
        phone=body.phone.strip() if body.phone else "",
        email=body.email.strip() if body.email else "",
        pin_hash=hash_secret(pin_to_hash),
        is_approved=True,  # Admin-created staff members are auto-approved
        is_email_verified=True,
    )
    db.add(staff)
    await db.commit()
    await db.refresh(staff)
    return staff


@router.put("/{staff_id}", response_model=StaffOut)
async def update_staff(staff_id: str, body: StaffUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Staff).where(Staff.id == staff_id))
    staff = result.scalar_one_or_none()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")
    if body.name is not None:
        staff.name = body.name.strip()
    if body.phone is not None:
        staff.phone = body.phone.strip()
    if body.email is not None:
        staff.email = body.email.strip()
    if body.pin is not None and body.pin.strip():
        staff.pin_hash = hash_secret(body.pin.strip())
    if body.is_active is not None:
        staff.is_active = body.is_active
    await db.commit()
    await db.refresh(staff)
    return staff


@router.delete("/{staff_id}")
async def deactivate_staff(
    staff_id: str,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(require_admin),
):
    """
    Hard delete billing member from database (Admin privilege required).
    """
    result = await db.execute(select(Staff).where(Staff.id == staff_id))
    staff = result.scalar_one_or_none()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")
    await db.delete(staff)
    await db.commit()
    return {"message": f"Staff member {staff.name} permanently deleted from database successfully"}
