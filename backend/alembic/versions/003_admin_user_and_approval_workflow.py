"""Add admin_users table and staff approval workflow columns

Revision ID: 003_admin_approval
Revises: 002_staff_pin
Create Date: 2026-08-31
"""
from alembic import op
import sqlalchemy as sa

revision = "003_admin_approval"
down_revision = "002_staff_pin"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # admin_users table
    op.create_table(
        "admin_users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("username", sa.String(100), nullable=False, unique=True),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(50), nullable=True, server_default=""),
        sa.Column("email", sa.String(255), nullable=True, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_admin_users_username", "admin_users", ["username"], unique=True)

    # staff approval columns
    op.add_column("staff", sa.Column("is_approved", sa.Boolean(), nullable=False, server_default="true"))
    op.add_column("staff", sa.Column("verification_code", sa.String(20), nullable=True, server_default=""))


def downgrade() -> None:
    op.drop_column("staff", "verification_code")
    op.drop_column("staff", "is_approved")
    op.drop_index("ix_admin_users_username", table_name="admin_users")
    op.drop_table("admin_users")
