import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Numeric, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


def utcnow():
    return datetime.now(timezone.utc)


class OpeningBalance(Base):
    __tablename__ = "opening_balances"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    bank_balance: Mapped[float] = mapped_column(Numeric(15, 2), default=0.0, nullable=False)
    cash_balance: Mapped[float] = mapped_column(Numeric(15, 2), default=0.0, nullable=False)
    cash_holder_staff_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("staff.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)
