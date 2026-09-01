"""
Atomic serial number generation.
Uses SELECT FOR UPDATE to prevent duplicate serial numbers under concurrent requests.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from app.models.document_sequence import DocumentSequence


PREFIXES = {
    "receipt": "R",
    "voucher": "V",
    "transfer": "T",
}


async def next_serial(db: AsyncSession, document_type: str) -> str:
    """
    Atomically increment and return the next serial number.
    Format: R-00001, V-00001, T-00001
    """
    prefix = PREFIXES.get(document_type, "X")

    # Lock the row for update
    result = await db.execute(
        select(DocumentSequence)
        .where(DocumentSequence.document_type == document_type)
        .with_for_update()
    )
    seq = result.scalar_one_or_none()

    if seq is None:
        seq = DocumentSequence(document_type=document_type, current_number=1)
        db.add(seq)
        await db.flush()
        number = 1
    else:
        seq.current_number += 1
        number = seq.current_number
        await db.flush()

    return f"{prefix}-{number:05d}"
