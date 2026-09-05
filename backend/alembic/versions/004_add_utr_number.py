"""Add utr_number column to transactions table

Revision ID: 004_utr_number
Revises: 003_admin_approval
Create Date: 2026-09-05
"""
from alembic import op
import sqlalchemy as sa

revision = "004_utr_number"
down_revision = "003_admin_approval"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("transactions", sa.Column("utr_number", sa.String(100), nullable=True, server_default=""))
    op.create_index("ix_transactions_utr_number", "transactions", ["utr_number"])


def downgrade() -> None:
    op.drop_index("ix_transactions_utr_number", table_name="transactions")
    op.drop_column("transactions", "utr_number")
