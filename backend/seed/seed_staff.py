"""
Seed initial billing staff members.
Run once after migrate: python -m seed.seed_staff
"""
import asyncio
import uuid
import asyncpg
import os

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://kovil_user:kovil_pass@localhost:5433/sembukutty_kovil"
).replace("postgresql+asyncpg://", "postgresql://")

INITIAL_STAFF = [
    "Raman",
    "Murugan",
    "Selvam",
    "Kannan",
    "Anbu",
]


async def main():
    print(f"Connecting to: {DATABASE_URL}")
    conn = await asyncpg.connect(DATABASE_URL)
    inserted = 0
    for name in INITIAL_STAFF:
        result = await conn.execute(
            "INSERT INTO staff(id, name, is_active, created_at, updated_at) "
            "VALUES($1, $2, true, NOW(), NOW()) ON CONFLICT DO NOTHING",
            str(uuid.uuid4()),
            name,
        )
        if result == "INSERT 0 1":
            inserted += 1
    count = await conn.fetchval("SELECT COUNT(*) FROM staff")
    print(f"Inserted {inserted} new staff. Total staff in DB: {count}")
    rows = await conn.fetch("SELECT name, is_active FROM staff ORDER BY name")
    for r in rows:
        print(f"  - {r['name']} (active={r['is_active']})")
    await conn.close()
    print("Done.")


if __name__ == "__main__":
    asyncio.run(main())
