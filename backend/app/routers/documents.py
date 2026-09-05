from typing import Optional
from datetime import date as DateType
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from app.database import get_db
from app.models.transaction import Transaction
from app.schemas import TransactionOut

router = APIRouter(prefix="/api/documents", tags=["documents"])


def _txn_to_out(t: Transaction) -> dict:
    return {
        "id": t.id, "staff_id": t.staff_id, "type": t.type,
        "date": str(t.date), "amount": float(t.amount), "mode": t.mode,
        "member_id": t.member_id, "member_name": t.member_name,
        "member_phone": t.member_phone, "address": t.address,
        "purpose": t.purpose, "remarks": t.remarks,
        "paid_to": t.paid_to, "direction": t.direction,
        "serial_number": t.serial_number, "utr_number": t.utr_number or "",
        "created_at": t.created_at, "updated_at": t.updated_at,
    }


@router.get("", response_model=list[TransactionOut])
async def list_documents(
    search: Optional[str] = Query(None),
    doc_type: Optional[str] = Query(None),  # receipt | voucher | transfer | all
    date_from: Optional[str] = Query(None),
    date_to: Optional[str] = Query(None),
    limit: int = Query(200, le=1000),
    db: AsyncSession = Depends(get_db),
):
    q = select(Transaction).where(Transaction.serial_number != None)

    if doc_type == "receipt":
        q = q.where(Transaction.type.in_(["tax", "donation"]))
    elif doc_type == "voucher":
        q = q.where(Transaction.type == "expense")
    elif doc_type == "transfer":
        q = q.where(Transaction.type == "transfer")

    if date_from:
        q = q.where(Transaction.date >= DateType.fromisoformat(date_from))
    if date_to:
        q = q.where(Transaction.date <= DateType.fromisoformat(date_to))

    if search and search.strip():
        term = f"%{search.strip()}%"
        q = q.where(or_(
            Transaction.serial_number.ilike(term),
            Transaction.utr_number.ilike(term),
            Transaction.member_name.ilike(term),
            Transaction.member_phone.ilike(term),
            Transaction.remarks.ilike(term),
            Transaction.purpose.ilike(term),
            Transaction.paid_to.ilike(term),
        ))

    q = q.order_by(Transaction.created_at.desc()).limit(limit)
    result = await db.execute(q)
    return [_txn_to_out(t) for t in result.scalars().all()]


@router.get("/{doc_id}", response_model=TransactionOut)
async def get_document(doc_id: str, db: AsyncSession = Depends(get_db)):
    from fastapi import HTTPException
    result = await db.execute(select(Transaction).where(Transaction.id == doc_id))
    txn = result.scalar_one_or_none()
    if not txn:
        raise HTTPException(status_code=404, detail="Document not found")
    return _txn_to_out(txn)
