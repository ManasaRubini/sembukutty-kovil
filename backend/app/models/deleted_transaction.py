import uuid
from datetime import datetime, timezone, date
from typing import Optional
from sqlalchemy import String, Numeric, DateTime, Date, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


def utcnow():
    return datetime.now(timezone.utc)


class DeletedTransaction(Base):
    __tablename__ = "deleted_transactions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    original_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    staff_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True, index=True)
    type: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Numeric(15, 2), nullable=False)
    mode: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)
    member_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    member_name: Mapped[Optional[str]] = mapped_column(String(512), nullable=True, default="")
    member_phone: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, default="")
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True, default="")
    purpose: Mapped[Optional[str]] = mapped_column(Text, nullable=True, default="")
    remarks: Mapped[Optional[str]] = mapped_column(Text, nullable=True, default="")
    paid_to: Mapped[Optional[str]] = mapped_column(String(512), nullable=True, default="")
    direction: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)
    serial_number: Mapped[Optional[str]] = mapped_column(String(20), nullable=True, index=True)
    utr_number: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, default="", index=True)
    deleted_by: Mapped[str] = mapped_column(String(100), nullable=False, default="Admin")
    deleted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
