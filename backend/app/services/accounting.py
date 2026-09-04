"""
Core accounting calculations.
All calculations match the original HTML application exactly.
"""
from datetime import date as DateType
from typing import Optional


def bank_balance_from_txns(opening_bank: float, txns: list) -> float:
    """
    Bank balance = opening + bank-mode tax/donation - bank-mode expense
                   + transfer deposits - transfer withdrawals
    """
    bal = opening_bank
    for t in txns:
        if t.type in ("tax", "donation") and t.mode == "bank":
            bal += float(t.amount)
        elif t.type == "expense" and t.mode == "bank":
            bal -= float(t.amount)
        elif t.type == "transfer":
            if t.direction == "deposit":
                bal += float(t.amount)
            elif t.direction == "withdraw":
                bal -= float(t.amount)
    return bal


def cash_balance_for_staff_from_txns(
    opening_cash: float,
    is_cash_holder: bool,
    txns: list,  # Already filtered to this staff
) -> float:
    """
    Staff cash = (opening cash if holder) + cash-mode tax/donation
                 - cash-mode expense - transfer deposits + transfer withdrawals
    """
    bal = opening_cash if is_cash_holder else 0.0
    for t in txns:
        if t.type in ("tax", "donation") and t.mode == "cash":
            bal += float(t.amount)
        elif t.type == "expense" and t.mode == "cash":
            bal -= float(t.amount)
        elif t.type == "transfer":
            if t.direction == "deposit":
                bal -= float(t.amount)
            elif t.direction == "withdraw":
                bal += float(t.amount)
    return max(0.0, bal)


def overall_cash_balance_from_txns(opening_cash: float, txns: list) -> float:
    """
    Overall Temple Cash = Opening Cash
                           + Cash Tax/Donations
                           - Cash Expenses
                           - Cash Deposited to Bank
                           + Cash Withdrawn from Bank
    """
    bal = opening_cash
    for t in txns:
        if t.type in ("tax", "donation") and t.mode == "cash":
            bal += float(t.amount)
        elif t.type == "expense" and t.mode == "cash":
            bal -= float(t.amount)
        elif t.type == "transfer":
            if t.direction == "deposit":
                bal -= float(t.amount)
            elif t.direction == "withdraw":
                bal += float(t.amount)
    return max(0.0, bal)


def totals_for_staff(txns: list) -> dict:
    tax = sum(float(t.amount) for t in txns if t.type == "tax")
    donation = sum(float(t.amount) for t in txns if t.type == "donation")
    expense = sum(float(t.amount) for t in txns if t.type == "expense")
    income = tax + donation
    net = income - expense
    return {"tax": tax, "donation": donation, "expense": expense, "income": income, "net": net}


async def get_opening(db):
    from sqlalchemy import select
    from app.models.opening_balance import OpeningBalance
    result = await db.execute(select(OpeningBalance).limit(1))
    return result.scalar_one_or_none()


async def get_all_staff(db):
    from sqlalchemy import select
    from app.models.staff import Staff
    result = await db.execute(select(Staff).where(Staff.is_active == True).order_by(Staff.created_at, Staff.id))
    return list(result.scalars().all())


async def get_transactions_for(
    db,
    staff_id: Optional[str] = None,
    as_of: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
):
    from sqlalchemy import select
    from app.models.transaction import Transaction
    q = select(Transaction)
    if staff_id:
        q = q.where(Transaction.staff_id == staff_id)
    if as_of:
        q = q.where(Transaction.date <= as_of)
    if date_from:
        q = q.where(Transaction.date >= date_from)
    if date_to:
        q = q.where(Transaction.date <= date_to)
    result = await db.execute(q)
    return list(result.scalars().all())


async def compute_dashboard(db, staff_id: Optional[str] = None) -> dict:
    """
    Compute dashboard metrics.
    Tax Collected, Donations, Expenses are COMBINED totals across ALL members (everyone).
    """
    from sqlalchemy import select
    from app.models.transaction import Transaction
    opening = await get_opening(db)

    opening_bank = float(opening.bank_balance) if opening else 0.0
    opening_cash = float(opening.cash_balance) if opening else 0.0
    cash_holder_id = opening.cash_holder_staff_id if opening else None

    # Fetch ALL transactions for combined totals across everyone
    all_txns_result = await db.execute(select(Transaction))
    all_txns = list(all_txns_result.scalars().all())

    # Combined totals for EVERYONE (tax, donation, expense)
    totals = totals_for_staff(all_txns)

    all_staff = await get_all_staff(db)
    first_staff_id = all_staff[0].id if all_staff else None

    # Cash in hand for current staff member
    if staff_id:
        my_txns = [t for t in all_txns if t.staff_id == staff_id]
        is_holder = (cash_holder_id == staff_id) if cash_holder_id else (staff_id == first_staff_id)
        my_cash = cash_balance_for_staff_from_txns(
            opening_cash,
            is_holder,
            my_txns,
        )
    else:
        my_cash = overall_cash_balance_from_txns(opening_cash, all_txns)

    bank_bal = bank_balance_from_txns(opening_bank, all_txns)
    total_cash = overall_cash_balance_from_txns(opening_cash, all_txns)

    # Recent 8 transactions across all members
    raw_recent = sorted(all_txns, key=lambda t: (str(t.date), str(t.created_at)), reverse=True)[:8]
    recent = [
        {
            "id": t.id,
            "staff_id": t.staff_id,
            "type": t.type,
            "date": str(t.date),
            "amount": float(t.amount),
            "mode": t.mode,
            "member_id": t.member_id,
            "member_name": t.member_name or "",
            "member_phone": t.member_phone or "",
            "address": t.address or "",
            "purpose": t.purpose or "",
            "remarks": t.remarks or "",
            "paid_to": t.paid_to or "",
            "direction": t.direction or "",
            "serial_number": t.serial_number or "",
            "created_at": t.created_at,
            "updated_at": t.updated_at,
        }
        for t in raw_recent
    ]

    return {
        "tax_collected": totals["tax"],
        "donations": totals["donation"],
        "expenses": totals["expense"],
        "income": totals["income"],
        "net": totals["net"],
        "my_cash": my_cash,
        "bank_balance": bank_bal,
        "total_cash": total_cash,
        "grand_total": bank_bal + total_cash,
        "recent_transactions": recent,
    }


async def compute_balance_report(db, scope: str, staff_id: Optional[str], as_of: str) -> dict:
    from sqlalchemy import select
    from app.models.transaction import Transaction
    opening = await get_opening(db)
    all_staff = await get_all_staff(db)

    opening_bank = float(opening.bank_balance) if opening else 0.0
    opening_cash = float(opening.cash_balance) if opening else 0.0
    cash_holder_id = opening.cash_holder_staff_id if opening else None

    # All txns up to as_of
    all_result = await db.execute(
        select(Transaction).where(Transaction.date <= as_of)
    )
    all_txns = list(all_result.scalars().all())

    bank_bal = bank_balance_from_txns(opening_bank, all_txns)

    first_staff_id = all_staff[0].id if all_staff else None

    if scope == "all":
        staff_list = all_staff
        total_cash = overall_cash_balance_from_txns(opening_cash, all_txns)
    elif scope == "mine" and staff_id:
        staff_list = [s for s in all_staff if s.id == staff_id]
        s_txns = [t for t in all_txns if t.staff_id == staff_id]
        is_holder = (cash_holder_id == staff_id) if cash_holder_id else (staff_id == first_staff_id)
        total_cash = cash_balance_for_staff_from_txns(
            opening_cash, is_holder, s_txns
        )
    else:
        staff_list = [s for s in all_staff if s.id == scope]
        s_txns = [t for t in all_txns if t.staff_id == scope]
        is_holder = (cash_holder_id == scope) if cash_holder_id else (scope == first_staff_id)
        total_cash = cash_balance_for_staff_from_txns(
            opening_cash, is_holder, s_txns
        )

    per_staff = []
    for s in staff_list:
        s_txns = [t for t in all_txns if t.staff_id == s.id]
        is_holder = (cash_holder_id == s.id) if cash_holder_id else (s.id == first_staff_id)
        cash = cash_balance_for_staff_from_txns(
            opening_cash, is_holder, s_txns
        )
        per_staff.append({"staff_id": s.id, "staff_name": s.name, "cash_balance": cash})

    return {
        "opening_bank": opening_bank,
        "opening_cash": opening_cash,
        "bank_balance": bank_bal,
        "total_cash": total_cash,
        "grand_total": bank_bal + total_cash,
        "per_staff": per_staff,
    }
