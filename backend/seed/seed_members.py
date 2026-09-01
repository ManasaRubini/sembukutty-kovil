"""
Seed script: imports 634 members from members_data.py into PostgreSQL.
Also seeds document_sequences (receipt, voucher, transfer).

Usage (from backend/ directory):
    python -m seed.seed_members
"""
import asyncio
import os
import uuid
import sys
from pathlib import Path

# Allow running from backend/ directory
sys.path.insert(0, str(Path(__file__).parent.parent))

from seed.members_data import MEMBERS_DATA


async def main():
    DATABASE_URL = os.environ.get(
        "DATABASE_URL",
        "postgresql+asyncpg://kovil_user:kovil_pass@localhost:5433/sembukutty_kovil"
    )

    # Use asyncpg directly for speed
    import asyncpg

    # Convert asyncpg:// to standard form
    url = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

    print(f"Connecting to: {url}")
    conn = await asyncpg.connect(url)

    inserted = 0
    skipped = 0

    # Seed document_sequences
    for doc_type in ("receipt", "voucher", "transfer"):
        await conn.execute("""
            INSERT INTO document_sequences (document_type, current_number)
            VALUES ($1, 0)
            ON CONFLICT (document_type) DO NOTHING
        """, doc_type)
    print("Document sequences seeded.")

    # Seed members
    for m in MEMBERS_DATA:
        name = m["name"].strip()
        phone = m["phone"].strip() if m.get("phone") else ""
        address = m["address"].strip() if m.get("address") else ""

        if not name:
            skipped += 1
            continue

        # Check for duplicate by name + phone
        existing = await conn.fetchval(
            "SELECT id FROM members WHERE name = $1 AND phone = $2",
            name, phone
        )
        if existing:
            skipped += 1
            continue

        mid = str(uuid.uuid4())
        await conn.execute(
            """INSERT INTO members (id, name, phone, address)
               VALUES ($1, $2, $3, $4)""",
            mid, name, phone, address
        )
        inserted += 1

    await conn.close()
    print(f"Members: {inserted} inserted, {skipped} skipped.")
    print("Seed complete!")


if __name__ == "__main__":
    asyncio.run(main())
