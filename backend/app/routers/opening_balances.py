import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models.opening_balance import OpeningBalance
from app.schemas import OpeningBalanceCreate, OpeningBalanceUpdate, OpeningBalanceOut

router = APIRouter(prefix="/api/opening-balances", tags=["opening-balances"])


@router.get("", response_model=OpeningBalanceOut)
async def get_opening_balance(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(OpeningBalance).limit(1))
    ob = result.scalar_one_or_none()
    if not ob:
        raise HTTPException(status_code=404, detail="Opening balance not set")
    return ob


@router.post("", response_model=OpeningBalanceOut)
async def create_opening_balance(body: OpeningBalanceCreate, db: AsyncSession = Depends(get_db)):
    # Only one opening balance record allowed
    result = await db.execute(select(OpeningBalance).limit(1))
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Opening balance already set. Use PUT to update.")
    ob = OpeningBalance(
        id=str(uuid.uuid4()),
        bank_balance=body.bank_balance,
        cash_balance=body.cash_balance,
        cash_holder_staff_id=body.cash_holder_staff_id,
    )
    db.add(ob)
    await db.commit()
    await db.refresh(ob)
    return ob


@router.put("", response_model=OpeningBalanceOut)
async def update_opening_balance(body: OpeningBalanceUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(OpeningBalance).limit(1))
    ob = result.scalar_one_or_none()
    if not ob:
        raise HTTPException(status_code=404, detail="Opening balance not set. Use POST to create.")
    if body.bank_balance is not None:
        ob.bank_balance = body.bank_balance
    if body.cash_balance is not None:
        ob.cash_balance = body.cash_balance
    if body.cash_holder_staff_id is not None:
        ob.cash_holder_staff_id = body.cash_holder_staff_id
    await db.commit()
    await db.refresh(ob)
    return ob
