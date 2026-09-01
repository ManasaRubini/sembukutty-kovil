"""Add pin_hash, phone, email to staff table

Revision ID: 002_staff_pin
Revises: 001_initial
Create Date: 2026-08-31
"""
from alembic import op
import sqlalchemy as sa

revision = "002_staff_pin"
down_revision = "001_initial"
branch_labels = None
depends_on = None

# Pre-computed bcrypt hash for default PIN "1234"
DEFAULT_PIN_HASH = "$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW"


def upgrade() -> None:
    op.add_column("staff", sa.Column("pin_hash", sa.String(255), nullable=True, server_default=DEFAULT_PIN_HASH))
    op.add_column("staff", sa.Column("phone", sa.String(50), nullable=True, server_default=""))
    op.add_column("staff", sa.Column("email", sa.String(255), nullable=True, server_default=""))
    op.create_index("ix_staff_phone", "staff", ["phone"])
    op.create_index("ix_staff_email", "staff", ["email"])


def downgrade() -> None:
    op.drop_index("ix_staff_email", table_name="staff")
    op.drop_index("ix_staff_phone", table_name="staff")
    op.drop_column("staff", "email")
    op.drop_column("staff", "phone")
    op.drop_column("staff", "pin_hash")
