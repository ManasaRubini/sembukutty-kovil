from typing import Optional
from datetime import date as DateType
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models.transaction import Transaction
from app.models.staff import Staff
from app.models.opening_balance import OpeningBalance
from app.schemas import CollectionSummary, ExpenseSummary, BalanceReport
from app.services.accounting import (
    bank_balance_from_txns,
    cash_balance_for_staff_from_txns,
)

router = APIRouter(prefix="/api/reports", tags=["reports"])


def _txn_to_dict(t: Transaction) -> dict:
    return {
        "id": t.id, "staff_id": t.staff_id, "type": t.type,
        "date": str(t.date), "amount": float(t.amount), "mode": t.mode,
        "member_id": t.member_id, "member_name": t.member_name,
        "member_phone": t.member_phone, "address": t.address,
        "purpose": t.purpose, "remarks": t.remarks,
        "paid_to": t.paid_to, "direction": t.direction,
        "serial_number": t.serial_number,
        "created_at": t.created_at, "updated_at": t.updated_at,
    }


async def _scoped_txns(
    db: AsyncSession, scope: str, staff_id: Optional[str],
    date_from: str, date_to: str
) -> list[Transaction]:
    q = select(Transaction).where(
        Transaction.date >= DateType.fromisoformat(date_from),
        Transaction.date <= DateType.fromisoformat(date_to),
    )
    if scope == "mine":
        if staff_id:
            q = q.where(Transaction.staff_id == staff_id)
        else:
            q = q.where(Transaction.staff_id == "admin")
    elif scope != "all":
        # scope is a specific staff_id
        q = q.where(Transaction.staff_id == scope)
    q = q.order_by(Transaction.date)
    result = await db.execute(q)
    return list(result.scalars().all())


@router.get("/collections", response_model=CollectionSummary)
async def collections_report(
    scope: str = Query("mine"),
    staff_id: Optional[str] = Query(None),
    date_from: str = Query(...),
    date_to: str = Query(...),
    db: AsyncSession = Depends(get_db),
):
    txns = await _scoped_txns(db, scope, staff_id, date_from, date_to)
    rows = [t for t in txns if t.type in ("tax", "donation")]
    total_tax = sum(float(t.amount) for t in rows if t.type == "tax")
    total_don = sum(float(t.amount) for t in rows if t.type == "donation")
    total_cash = sum(float(t.amount) for t in rows if t.mode == "cash")
    total_bank = sum(float(t.amount) for t in rows if t.mode == "bank")
    return CollectionSummary(
        total_tax=total_tax,
        total_donations=total_don,
        total_cash=total_cash,
        total_bank=total_bank,
        total_collections=total_tax + total_don,
        rows=[_txn_to_dict(t) for t in rows],
    )


@router.get("/expenses", response_model=ExpenseSummary)
async def expenses_report(
    scope: str = Query("mine"),
    staff_id: Optional[str] = Query(None),
    date_from: str = Query(...),
    date_to: str = Query(...),
    db: AsyncSession = Depends(get_db),
):
    txns = await _scoped_txns(db, scope, staff_id, date_from, date_to)
    rows = [t for t in txns if t.type == "expense"]
    total = sum(float(t.amount) for t in rows)
    total_cash = sum(float(t.amount) for t in rows if t.mode == "cash")
    total_bank = sum(float(t.amount) for t in rows if t.mode == "bank")
    return ExpenseSummary(
        total_expenses=total,
        total_cash=total_cash,
        total_bank=total_bank,
        rows=[_txn_to_dict(t) for t in rows],
    )


@router.get("/balances", response_model=BalanceReport)
async def balances_report(
    scope: str = Query("all"),
    staff_id: Optional[str] = Query(None),
    as_of: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    today = DateType.today().isoformat()
    as_of_date = as_of or today

    ob_result = await db.execute(select(OpeningBalance).limit(1))
    opening = ob_result.scalar_one_or_none()
    opening_bank = float(opening.bank_balance) if opening else 0.0
    opening_cash = float(opening.cash_balance) if opening else 0.0
    cash_holder_id = opening.cash_holder_staff_id if opening else None

    all_txns_result = await db.execute(
        select(Transaction).where(Transaction.date <= DateType.fromisoformat(as_of_date))
    )
    all_txns = list(all_txns_result.scalars().all())

    bank_bal = bank_balance_from_txns(opening_bank, all_txns)

    staff_result = await db.execute(select(Staff).where(Staff.is_active == True))
    all_staff = list(staff_result.scalars().all())

    if scope == "all":
        staff_list = all_staff
    elif scope == "mine" and staff_id:
        staff_list = [s for s in all_staff if s.id == staff_id]
    else:
        staff_list = [s for s in all_staff if s.id == scope]

    per_staff = []
    total_cash = 0.0
    for s in staff_list:
        s_txns = [t for t in all_txns if t.staff_id == s.id]
        cash = cash_balance_for_staff_from_txns(
            opening_cash, cash_holder_id == s.id, s_txns
        )
        total_cash += cash
        per_staff.append({"staff_id": s.id, "staff_name": s.name, "cash_balance": cash})

    return BalanceReport(
        opening_bank=opening_bank,
        opening_cash=opening_cash,
        bank_balance=bank_bal,
        total_cash=total_cash,
        grand_total=bank_bal + total_cash,
        per_staff=per_staff,
    )
