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
from app.services.accounting import get_current_bank_balance, get_current_staff_cash_balance
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


@router.get("/check-utr/{utr_number}")
async def check_utr(utr_number: str, db: AsyncSession = Depends(get_db)):
    utr_clean = utr_number.strip()
    if not utr_clean:
        return {"already_billed": False}

    q = (
        select(Transaction, Staff.name)
        .outerjoin(Staff, Transaction.staff_id == Staff.id)
        .where(Transaction.utr_number == utr_clean)
    )
    result = await db.execute(q)
    row = result.first()

    if row:
        txn, staff_name = row
        return {
            "already_billed": True,
            "billed_by": staff_name or "Another Billing Member",
            "date": str(txn.date),
            "amount": float(txn.amount),
            "serial_number": txn.serial_number or "",
            "member_name": txn.member_name or "",
            "message": f"Already Billed! This UTR No. ({utr_clean}) was billed by {staff_name or 'another member'} on {txn.date} for ₹{float(txn.amount):,.2f} (Receipt #{txn.serial_number or '—'})."
        }

    return {"already_billed": False}


@router.post("", response_model=TransactionOut)
async def create_transaction(body: TransactionCreate, db: AsyncSession = Depends(get_db)):
    _validate_transaction(body)

    # Verify staff exists
    staff_result = await db.execute(select(Staff).where(Staff.id == body.staff_id))
    staff = staff_result.scalar_one_or_none()
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")

    txn_date = DateType.fromisoformat(body.date)
    utr_clean = (body.utr_number or "").strip()

    # 1. Check UTR uniqueness & requirement for Bank payments
    if body.mode == "bank":
        if not utr_clean:
            raise HTTPException(
                status_code=422,
                detail="UTR / Bank Reference Number is required for Bank Transfer payments."
            )
        
        utr_check = await db.execute(
            select(Transaction, Staff.name)
            .outerjoin(Staff, Transaction.staff_id == Staff.id)
            .where(Transaction.utr_number == utr_clean)
        )
        row = utr_check.first()
        if row:
            existing_txn, billed_by = row
            staff_name = billed_by or "another billing member"
            raise HTTPException(
                status_code=400,
                detail=f"Already Billed! UTR No. '{utr_clean}' was already billed by {staff_name} on {existing_txn.date} (Receipt #{existing_txn.serial_number or '—'})."
            )

    # 2. General duplicate entry check (same date, amount, type, member_name, purpose)
    dup_q = select(Transaction).where(
        Transaction.date == txn_date,
        Transaction.amount == body.amount,
        Transaction.type == body.type,
        Transaction.member_name == (body.member_name or ""),
        Transaction.purpose == (body.purpose or ""),
    )
    dup_check = await db.execute(dup_q)
    if dup_check.scalars().first():
        raise HTTPException(
            status_code=400,
            detail="Duplicate entry rejected! An identical transaction with the same date, devotee, purpose and amount already exists."
        )

    # 3. Balance verification (Cash in hand for cash expenses/deposits, Bank balance for bank expenses/withdrawals)
    if body.type == "expense":
        if body.mode == "cash":
            current_cash = await get_current_staff_cash_balance(db, body.staff_id)
            if body.amount > current_cash:
                raise HTTPException(
                    status_code=400,
                    detail=f"Insufficient Cash in Hand! Your available cash balance is ₹{current_cash:,.2f}, but requested expense is ₹{body.amount:,.2f}."
                )
        elif body.mode == "bank":
            current_bank = await get_current_bank_balance(db)
            if body.amount > current_bank:
                raise HTTPException(
                    status_code=400,
                    detail=f"Insufficient Bank Balance! Available bank balance is ₹{current_bank:,.2f}, but requested expense is ₹{body.amount:,.2f}."
                )

    elif body.type == "transfer":
        if body.direction == "deposit":
            # Cash deposit to bank -> reduces member's cash in hand
            current_cash = await get_current_staff_cash_balance(db, body.staff_id)
            if body.amount > current_cash:
                raise HTTPException(
                    status_code=400,
                    detail=f"Insufficient Cash in Hand! Your available cash balance is ₹{current_cash:,.2f}, but requested deposit is ₹{body.amount:,.2f}."
                )
        elif body.direction == "withdraw":
            # Cash withdrawal from bank -> reduces temple bank balance
            current_bank = await get_current_bank_balance(db)
            if body.amount > current_bank:
                raise HTTPException(
                    status_code=400,
                    detail=f"Insufficient Bank Balance! Available bank balance is ₹{current_bank:,.2f}, but requested withdrawal is ₹{body.amount:,.2f}."
                )

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
        utr_number=utr_clean,
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
        "utr_number": t.utr_number or "",
        "created_at": t.created_at,
        "updated_at": t.updated_at,
    }
