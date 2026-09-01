import asyncio
import asyncpg
import os
import hashlib

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://kovil_user:kovil_pass@postgres:5432/sembukutty_kovil"
).replace("postgresql+asyncpg://", "postgresql://")


def hash_secret(secret: str) -> str:
    salt = "sembukutty_kovil_salt_2026"
    return hashlib.sha256(f"{salt}:{secret}".encode("utf-8")).hexdigest()


async def main():
    conn = await asyncpg.connect(DATABASE_URL)
    pin_h = hash_secret("1234")
    staff_contacts = [
        ("Raman", "9840729001", "raman@kovil.com"),
        ("Murugan", "9840729002", "murugan@kovil.com"),
        ("Selvam", "9840729003", "selvam@kovil.com"),
        ("Kannan", "9840729004", "kannan@kovil.com"),
        ("Anbu", "9840729005", "anbu@kovil.com"),
    ]
    for name, phone, email in staff_contacts:
        await conn.execute(
            "UPDATE staff SET phone = $1, email = $2, pin_hash = $3 WHERE name = $4",
            phone, email, pin_h, name
        )
    
    rows = await conn.fetch("SELECT name, phone, email FROM staff ORDER BY name")
    print("Staff records updated:")
    for r in rows:
        print(f"  - {r['name']}: Phone={r['phone']}, Email={r['email']}")
    await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
