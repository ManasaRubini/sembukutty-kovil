"""Initial schema

Revision ID: 001_initial
Revises:
Create Date: 2026-08-30
"""
from alembic import op
import sqlalchemy as sa

revision = "001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # staff
    op.create_table(
        "staff",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # members
    op.create_table(
        "members",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(512), nullable=False),
        sa.Column("phone", sa.String(100), nullable=True, server_default=""),
        sa.Column("address", sa.Text(), nullable=True, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_members_name", "members", ["name"])

    # opening_balances
    op.create_table(
        "opening_balances",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("bank_balance", sa.Numeric(15, 2), nullable=False, server_default="0"),
        sa.Column("cash_balance", sa.Numeric(15, 2), nullable=False, server_default="0"),
        sa.Column("cash_holder_staff_id", sa.String(36), sa.ForeignKey("staff.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # transactions
    op.create_table(
        "transactions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("staff_id", sa.String(36), sa.ForeignKey("staff.id", ondelete="SET NULL"), nullable=True),
        sa.Column("type", sa.String(20), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("amount", sa.Numeric(15, 2), nullable=False),
        sa.Column("mode", sa.String(10), nullable=True),
        sa.Column("member_id", sa.String(36), sa.ForeignKey("members.id", ondelete="SET NULL"), nullable=True),
        sa.Column("member_name", sa.String(512), nullable=True, server_default=""),
        sa.Column("member_phone", sa.String(100), nullable=True, server_default=""),
        sa.Column("address", sa.Text(), nullable=True, server_default=""),
        sa.Column("purpose", sa.Text(), nullable=True, server_default=""),
        sa.Column("remarks", sa.Text(), nullable=True, server_default=""),
        sa.Column("paid_to", sa.String(512), nullable=True, server_default=""),
        sa.Column("direction", sa.String(10), nullable=True),
        sa.Column("serial_number", sa.String(20), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_transactions_staff_id", "transactions", ["staff_id"])
    op.create_index("ix_transactions_type", "transactions", ["type"])
    op.create_index("ix_transactions_date", "transactions", ["date"])
    op.create_index("ix_transactions_serial", "transactions", ["serial_number"])
    op.create_index("ix_transactions_created_at", "transactions", ["created_at"])

    # document_sequences
    op.create_table(
        "document_sequences",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("document_type", sa.String(20), nullable=False, unique=True),
        sa.Column("current_number", sa.Integer(), nullable=False, server_default="0"),
    )
    op.create_index("ix_document_sequences_type", "document_sequences", ["document_type"])


def downgrade() -> None:
    op.drop_table("transactions")
    op.drop_table("document_sequences")
    op.drop_table("opening_balances")
    op.drop_table("members")
    op.drop_table("staff")
