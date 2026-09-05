import uuid
from datetime import datetime, timezone, date
from sqlalchemy import String, Numeric, DateTime, Date, ForeignKey, Text, Enum
from sqlalchemy.orm import Mapped, mapped_column
import enum
from app.database import Base


def utcnow():
    return datetime.now(timezone.utc)


class TransactionType(str, enum.Enum):
    tax = "tax"
    donation = "donation"
    expense = "expense"
    transfer = "transfer"


class PaymentMode(str, enum.Enum):
    cash = "cash"
    bank = "bank"


class TransferDirection(str, enum.Enum):
    deposit = "deposit"
    withdraw = "withdraw"


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    staff_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("staff.id", ondelete="SET NULL"), nullable=True, index=True
    )
    type: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Numeric(15, 2), nullable=False)
    mode: Mapped[str] = mapped_column(String(10), nullable=True)   # cash | bank | None for transfer
    member_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("members.id", ondelete="SET NULL"), nullable=True
    )
    member_name: Mapped[str] = mapped_column(String(512), nullable=True, default="")
    member_phone: Mapped[str] = mapped_column(String(100), nullable=True, default="")
    address: Mapped[str] = mapped_column(Text, nullable=True, default="")
    purpose: Mapped[str] = mapped_column(Text, nullable=True, default="")
    remarks: Mapped[str] = mapped_column(Text, nullable=True, default="")
    paid_to: Mapped[str] = mapped_column(String(512), nullable=True, default="")
    direction: Mapped[str] = mapped_column(String(10), nullable=True)  # deposit | withdraw
    serial_number: Mapped[str] = mapped_column(String(20), nullable=True, index=True)
    utr_number: Mapped[str] = mapped_column(String(100), nullable=True, default="", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)
