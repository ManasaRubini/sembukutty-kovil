import os
import subprocess
import sys
from datetime import datetime
from urllib.parse import urlparse

# Add parent dir to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from app.config import settings


def run_backup():
    db_url = settings.DATABASE_URL
    # Parse mysql://user:pass@host:port/dbname
    clean_url = db_url.replace("mysql+aiomysql://", "mysql://").replace("mysql+pymysql://", "mysql://")
    parsed = urlparse(clean_url)

    user = parsed.username or "temple_app"
    password = parsed.password or ""
    host = parsed.hostname or "127.0.0.1"
    port = parsed.port or 3306
    dbname = parsed.path.lstrip("/") or "temple_db"

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "backups"))
    os.makedirs(backup_dir, exist_ok=True)

    backup_file = os.path.join(backup_dir, f"{dbname}_backup_{timestamp}.sql")

    print(f"[*] Starting MySQL database backup for database '{dbname}'...")
    print(f"[*] Target backup file: {backup_file}")

    cmd = [
        "mysqldump",
        f"--host={host}",
        f"--port={port}",
        f"--user={user}",
        f"--password={password}",
        "--routines",
        "--triggers",
        "--single-transaction",
        dbname,
    ]

    try:
        with open(backup_file, "w", encoding="utf-8") as f:
            result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE, text=True, check=True)
        print(f"[✓] MySQL Database backup completed successfully: {backup_file}")
    except FileNotFoundError:
        print("[!] Warning: 'mysqldump' utility was not found in PATH. Please install MySQL tools or add mysqldump to System PATH.")
    except subprocess.CalledProcessError as e:
        print(f"[!] Backup failed: {e.stderr}")


if __name__ == "__main__":
    run_backup()
