import asyncio
import os
import asyncpg

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://kovil_user:kovil_pass@localhost:5432/sembukutty_kovil"
).replace("postgresql+asyncpg://", "postgresql://")


async def main():
    print(f"Connecting to: {DATABASE_URL}")
    try:
        conn = await asyncpg.connect(DATABASE_URL)
        res = await conn.execute(
            "UPDATE admin_users SET email = $1 WHERE username = 'admin' OR email IS NULL OR email = '' OR email = 'admin@kovil.com'",
            "sembukuttysastha.kovil@gmail.com"
        )
        print(f"Update result: {res}")
        rows = await conn.fetch("SELECT id, username, email, phone FROM admin_users")
        for r in rows:
            print(f"  - Admin: {r['username']} | Email: {r['email']} | Phone: {r['phone']}")
        await conn.close()
    except Exception as e:
        print(f"Error updating admin email in DB: {e}")

if __name__ == "__main__":
    asyncio.run(main())
