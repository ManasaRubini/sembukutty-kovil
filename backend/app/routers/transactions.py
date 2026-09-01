import uuid
from datetime import date as DateType
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models.transaction import Transaction
from app.models.staff import Staff
from app.models.member import Member
from app.schemas import TransactionCreate, TransactionOut
from app.services.serial import next_serial
from app.routers.auth import require_admin, get_current_user

router = APIRouter(prefix="/api/transactions", tags=["transactions"])

VALID_TYPES = {"tax", "donation", "expense", "transfer"}
VALID_MODES = {"cash", "bank"}
VALID_DIRECTIONS = {"deposit", "withdraw"}


def _validate_transaction(body: TransactionCreate):
    if body.type not in VALID_TYPES:
        raise HTTPException(status_code=422, detail=f"Invalid type. Must be one of: {VALID_TYPES}")
    if body.amount <= 0:
        raise HTTPException(status_code=422, detail="Amount must be greater than 0")
    if not body.date:
        raise HTTPException(status_code=422, detail="Date is required")
    if body.type in ("tax", "donation"):
        if body.mode not in VALID_MODES:
            raise HTTPException(status_code=422, detail="Payment mode (cash/bank) is required for tax/donation")
    elif body.type == "expense":
        if body.mode not in VALID_MODES:
            raise HTTPException(status_code=422, detail="Payment mode (cash/bank) is required for expense")
        if not body.remarks:
            raise HTTPException(status_code=422, detail="Purpose/remarks is required for expenses")
    elif body.type == "transfer":
        if body.direction not in VALID_DIRECTIONS:
            raise HTTPException(status_code=422, detail="Direction (deposit/withdraw) is required for transfer")


@router.post("", response_model=TransactionOut)
async def create_transaction(body: TransactionCreate, db: AsyncSession = Depends(get_db)):
    _validate_transaction(body)

    # Verify staff exists
    staff_result = await db.execute(select(Staff).where(Staff.id == body.staff_id))
    staff = staff_result.scalar_one_or_none()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")

    # Auto-save or update Devotee record in members database table
    member_id_final = body.member_id
    if body.member_name and body.member_name.strip() and body.member_name.strip() != "Walk-in / Unspecified":
        m_name = body.member_name.strip()
        m_phone = (body.member_phone or "").strip()
        m_address = (body.address or "").strip()

        m_existing = None
        if member_id_final:
            m_res = await db.execute(select(Member).where(Member.id == member_id_final))
            m_existing = m_res.scalar_one_or_none()

        if not m_existing:
            m_res = await db.execute(select(Member).where(Member.name == m_name))
            m_existing = m_res.scalars().first()

        if m_existing:
            if m_phone and not m_existing.phone:
                m_existing.phone = m_phone
            if m_address and not m_existing.address:
                m_existing.address = m_address
            member_id_final = m_existing.id
        else:
            new_member = Member(
                id=str(uuid.uuid4()),
                name=m_name,
                phone=m_phone,
                address=m_address,
            )
            db.add(new_member)
            await db.flush()
            member_id_final = new_member.id

    # Determine serial type
    if body.type == "expense":
        serial_type = "voucher"
    elif body.type == "transfer":
        serial_type = "transfer"
    else:
        serial_type = "receipt"

    # Generate serial number atomically (within this transaction)
    serial = await next_serial(db, serial_type)

    txn_date = DateType.fromisoformat(body.date)

    txn = Transaction(
        id=str(uuid.uuid4()),
        staff_id=body.staff_id,
        type=body.type,
        date=txn_date,
        amount=body.amount,
        mode=body.mode,
        member_id=member_id_final,
        member_name=body.member_name or "",
        member_phone=body.member_phone or "",
        address=body.address or "",
        purpose=body.purpose or "",
        remarks=body.remarks or "",
        paid_to=body.paid_to or "",
        direction=body.direction,
        serial_number=serial,
    )
    db.add(txn)
    await db.commit()
    await db.refresh(txn)
    return _txn_to_out(txn)


@router.get("", response_model=list[TransactionOut])
async def list_transactions(
    staff_id: Optional[str] = None,
    type: Optional[str] = None,
    mode: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    limit: int = Query(500, le=2000),
    db: AsyncSession = Depends(get_db),
):
    q = select(Transaction)
    if staff_id:
        q = q.where(Transaction.staff_id == staff_id)
    if type:
        q = q.where(Transaction.type == type)
    if mode:
        q = q.where(Transaction.mode == mode)
    if date_from:
        q = q.where(Transaction.date >= DateType.fromisoformat(date_from))
    if date_to:
        q = q.where(Transaction.date <= DateType.fromisoformat(date_to))
    q = q.order_by(Transaction.date.desc(), Transaction.created_at.desc()).limit(limit)
    result = await db.execute(q)
    return [_txn_to_out(t) for t in result.scalars().all()]


@router.get("/{txn_id}", response_model=TransactionOut)
async def get_transaction(txn_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Transaction).where(Transaction.id == txn_id))
    txn = result.scalar_one_or_none()
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return _txn_to_out(txn)


@router.delete("/{txn_id}")
async def delete_transaction(
    txn_id: str,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(require_admin),
):
    result = await db.execute(select(Transaction).where(Transaction.id == txn_id))
    txn = result.scalar_one_or_none()
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")
    await db.delete(txn)
    await db.commit()
    return {"message": "Transaction deleted"}


def _txn_to_out(t: Transaction) -> dict:
    return {
        "id": t.id,
        "staff_id": t.staff_id,
        "type": t.type,
        "date": str(t.date),
        "amount": float(t.amount),
        "mode": t.mode,
        "member_id": t.member_id,
        "member_name": t.member_name,
        "member_phone": t.member_phone,
        "address": t.address,
        "purpose": t.purpose,
        "remarks": t.remarks,
        "paid_to": t.paid_to,
        "direction": t.direction,
        "serial_number": t.serial_number,
        "created_at": t.created_at,
        "updated_at": t.updated_at,
    }
