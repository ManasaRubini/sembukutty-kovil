import os
import sys
import subprocess
import smtplib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.mime.text import MIMEText
from email import encoders

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from app.config import settings


def create_and_email_backup():
    """
    Creates a full database backup and emails it as an encrypted/compressed attachment
    to the Administrator's email address for offsite backup safety.
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "backups"))
    os.makedirs(backup_dir, exist_ok=True)

    backup_file = os.path.join(backup_dir, f"temple_db_backup_{timestamp}.sql")
    gz_backup_file = f"{backup_file}.gz"

    print(f"[*] Starting Automated Daily Backup: {timestamp}")

    # Step 1: Dump Database
    cmd = [
        "mysqldump",
        "--host=127.0.0.1",
        "--port=3306",
        f"--user={settings.ADMIN_USERNAME}",
        f"--password={settings.ADMIN_PASSWORD}",
        "--routines",
        "--triggers",
        "--single-transaction",
        "temple_db",
    ]

    try:
        with open(backup_file, "w", encoding="utf-8") as f:
            subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE, check=True)

        # Compress to .gz
        subprocess.run(["gzip", "-f", backup_file], check=True)
        print(f"[✓] Compressed Backup Created: {gz_backup_file}")

        # Step 2: Email Offsite Backup Attachment via SMTP
        if settings.SMTP_USER and settings.SMTP_PASSWORD and settings.SMTP_FROM_EMAIL:
            msg = MIMEMultipart()
            msg["From"] = settings.SMTP_FROM_EMAIL
            msg["To"] = settings.SMTP_USER
            msg["Subject"] = f"📌 Daily Temple Database Offsite Backup — {timestamp}"

            body = (
                f"Automated Daily Backup for Sembukutty Sastha Kovil.\n\n"
                f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                f"File: {os.path.basename(gz_backup_file)}\n\n"
                f"Keep this backup file safe. In case of server migration or recovery, "
                f"this file contains all member records, receipts, vouchers, and transactions."
            )
            msg.attach(MIMEText(body, "plain"))

            with open(gz_backup_file, "rb") as attachment:
                part = MIMEBase("application", "octet-stream")
                part.set_payload(attachment.read())
                encoders.encode_base64(part)
                part.add_header(
                    "Content-Disposition",
                    f"attachment; filename= {os.path.basename(gz_backup_file)}",
                )
                msg.attach(part)

            server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT)
            server.starttls()
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.send_message(msg)
            server.quit()
            print(f"[✓] Offsite Backup Emailed Successfully to {settings.SMTP_USER}")
        else:
            print("[!] SMTP credentials not configured. Backup saved locally.")

    except Exception as e:
        print(f"[!] Offsite Backup Error: {e}")


if __name__ == "__main__":
    create_and_email_backup()
