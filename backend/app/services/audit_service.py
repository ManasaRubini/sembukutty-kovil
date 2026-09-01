import json
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.audit_log import AuditLog


async def log_audit_event(
    db: AsyncSession,
    action: str,
    user_id: Optional[str] = None,
    user_role: Optional[str] = None,
    entity_type: Optional[str] = None,
    entity_id: Optional[str] = None,
    ip_address: Optional[str] = None,
    details: Optional[dict] = None,
):
    """
    Logs an audit event to the database audit_logs table.
    Filters out sensitive keys (passwords, tokens, pins) automatically.
    """
    safe_details_str = ""
    if details:
        safe_copy = dict(details)
        for k in ["password", "pin", "token", "otp", "secret"]:
            if k in safe_copy:
                safe_copy[k] = "[REDACTED]"
        safe_details_str = json.dumps(safe_copy)

    audit = AuditLog(
        action=action,
        user_id=user_id,
        user_role=user_role,
        entity_type=entity_type,
        entity_id=entity_id,
        ip_address=ip_address,
        details=safe_details_str,
    )
    db.add(audit)
    try:
        await db.commit()
    except Exception:
        await db.rollback()
