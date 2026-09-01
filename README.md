# Secure Temple Billing & Member Management System — Cloudflare Tunnel & MySQL Architecture

A production-ready, security-hardened **Temple Billing and Member Management System** built with **Flutter**, **FastAPI**, **Argon2id Hashing**, **MySQL**, and **Cloudflare Named Tunnels**.

---

## 1. System Architecture

```text
                    Internet (Android / iPhone / Laptop)
                                    │
                                    │ HTTPS (WAF, DDoS Protection)
                                    ▼
                           ┌─────────────────┐
                           │    Cloudflare   │
                           │  Named Tunnel   │
                           └────────┬────────┘
                                    │
                              Secure Tunnel
                                    │
                                    ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ Windows Server                                                  │
 │                                                                 │
 │   ┌──────────────────┐       ┌──────────────────────────────┐   │
 │   │   cloudflared    │ ─────►│ FastAPI (127.0.0.1:8000)   │   │
 │   │ Windows Service  │       │  - Argon2id Hashing          │   │
 │   └──────────────────┘       │  - JWT Access/Refresh        │   │
 │                              │  - RBAC (ADMIN/STAFF/VIEWER) │   │
 │                              │  - Audit Logging             │   │
 │                              └──────────────┬───────────────┘   │
 │                                             │                   │
 │                                             ▼                   │
 │                              ┌──────────────────────────────┐   │
 │                              │ MySQL DB (127.0.0.1:3306)    │   │
 │                              └──────────────────────────────┘   │
 └─────────────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Zero Public Port Exposure**:
> - Port 8000 (FastAPI) is bound strictly to `127.0.0.1:8000` (localhost).
> - Port 3306 (MySQL) is bound strictly to `127.0.0.1:3306` (localhost).
> - No router port forwarding or public port exposure is used.
> - All incoming mobile app traffic passes through encrypted Cloudflare Named Tunnels (`cloudflared`).

---

## 2. Cloudflare Named Tunnel Windows Setup Guide

Follow these steps to set up a permanent, production-grade **Cloudflare Named Tunnel** on Windows:

### Step 1: Install `cloudflared` on Windows
1. Download `cloudflared-windows-amd64.exe` from [Cloudflare Releases](https://github.com/cloudflare/cloudflared/releases).
2. Move executable to `C:\cloudflared\cloudflared.exe`.
3. Add `C:\cloudflared` to System `PATH`.

### Step 2: Authenticate Cloudflare
Open Command Prompt as Administrator:
```cmd
cloudflared tunnel login
```
* A browser window opens. Log in to your Cloudflare account and select your domain (e.g., `example.com`).

### Step 3: Create a Named Tunnel
```cmd
cloudflared tunnel create temple-billing-tunnel
```
* Output returns your **Tunnel ID** (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`) and saves credential file to `C:\cloudflared\<TUNNEL_ID>.json`.

### Step 4: Route your Subdomain to the Tunnel
```cmd
cloudflared tunnel route dns temple-billing-tunnel billing.example.com
```

### Step 5: Configure `cloudflare/config.yml`
Save the configuration file at `C:\cloudflared\config.yml`:

```yaml
tunnel: a1b2c3d4-e5f6-7890-abcd-ef1234567890
credentials-file: C:\cloudflared\a1b2c3d4-e5f6-7890-abcd-ef1234567890.json

ingress:
  # Route subdomain to FastAPI local server
  - hostname: billing.example.com
    service: http://localhost:8000

  # Default 404 for unmapped requests
  - service: http_status:404
```

### Step 6: Install & Run as a Windows Service
```cmd
# Install as Windows Service
cloudflared service install

# Start Windows Service
net start cloudflared
```

### Step 7: Verify Tunnel Health & Automatic Restart
```cmd
cloudflared tunnel info temple-billing-tunnel
```
* The service automatically restarts on Windows reboot, ensuring 24/7 uptime without manual intervention.

---

## 3. MySQL Database Setup & Security

### Step 1: Install MySQL Server 8.x
Install MySQL Server 8.x on your Windows machine and ensure it binds strictly to `127.0.0.1`:
In `my.ini` / `my.cnf`:
```ini
[mysqld]
bind-address = 127.0.0.1
port = 3306
```

### Step 2: Create Restricted Database User
Execute in MySQL Workbench or Command Line:
```sql
CREATE DATABASE temple_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create application user (NO root access)
CREATE USER 'temple_app'@'127.0.0.1' IDENTIFIED BY 'KovilApp@2026';

-- Grant required permissions
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, ALTER ON temple_db.* TO 'temple_app'@'127.0.0.1';
FLUSH PRIVILEGES;
```

---

## 4. Role-Based Access Control (RBAC) & Security Specs

| Role | Access Level | Permissions |
| :--- | :--- | :--- |
| **`ADMIN`** | Full System Access | Create/Delete Users, Manage Members, Edit Payments & Receipts, View Audit Logs, Modify System Settings, Daily Backups |
| **`STAFF`** | Billing Operations | Add/Update Members, Create Receipts & Vouchers, View Payments |
| **`VIEWER`** | Read-Only | View Authorized Records & Reports (No mutations or deletes allowed) |

### Password & Secret Security
* **Argon2id Hashing**: All passwords & PINs hashed using Argon2id (`time_cost=3, memory_cost=64MB, parallelism=4`).
* **JWT Access & Refresh Tokens**: Short-lived access tokens (15 mins) + refresh tokens (7 days).
* **HTTP Security Headers**: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`.
* **Rate Limiting**: Integrated `slowapi` brute-force protection.
* **Audit Trail**: Every sensitive operation (login, create, update, delete) is logged to `audit_logs` table (`user_id`, `action`, `entity_type`, `entity_id`, `ip_address`).

---

## 5. Automated MySQL Daily Backup Script

Automated backup script: [`backend/scripts/backup_mysql.py`](file:///C:/Users/manas/Downloads/SEMBUKUTTY%20SASTHA%20KOVIL/backend/scripts/backup_mysql.py)

### Run Manual Backup:
```cmd
cd backend
python -m scripts.backup_mysql
```

### Automate Daily via Windows Task Scheduler:
1. Open **Windows Task Scheduler**.
2. Action: `Start a Program` -> `python.exe`.
3. Arguments: `C:\Users\manas\Downloads\SEMBUKUTTY SASTHA KOVIL\backend\scripts\backup_mysql.py`.
4. Trigger: Daily at `02:00 AM`.

---

## 6. Security Audit & Remaining Risks

> [!WARNING]
> **Security Disclaimer**: No application is "100% unhackable". Below are remaining risks and recommended mitigation steps:

1. **Host Physical Security**:
   - *Risk*: Physical theft or unauthorized access to the Windows server host machine.
   - *Mitigation*: Enable Windows BitLocker full-disk encryption and restrict physical computer access.
2. **Offsite Backup Storage**:
   - *Risk*: Hardware disk failure on the server computer.
   - *Mitigation*: Configure daily sync of the `backups/` directory to encrypted cloud storage (e.g., Google Drive / OneDrive).
3. **Cloudflare Zero Trust Access for Admin**:
   - *Risk*: Unauthorized attempts on public `/admin` routes.
   - *Mitigation*: Enable Cloudflare Access / Zero Trust rules on `billing.example.com/admin/*` requiring One-Time PIN email authentication.

---

## 7. Oracle Cloud Always Free & Automated Offsite Email Backup

### Automated Daily Email Backup Strategy
To ensure your temple accounting data is **100% safe and never lost** (even if Oracle Cloud terminates or reclaims an idle instance), we created an automated offsite backup service: [`backend/scripts/offsite_backup.py`](file:///C:/Users/manas/Downloads/SEMBUKUTTY%20SASTHA%20KOVIL/backend/scripts/offsite_backup.py).

#### How it protects your data:
1. Every night at 02:00 AM, `cron` executes `python -m scripts.offsite_backup`.
2. It dumps the database to a compressed file: `temple_db_backup_YYYYMMDD_HHMMSS.sql.gz`.
3. It automatically sends the compressed backup as an email attachment to the Administrator's email via SMTP!
4. **Result**: Your data is always safely backed up in your personal Email / Google Drive. If the server is ever shut down or lost, you can restore all receipts and member records in 1 minute on any new machine!

---

## 8. License

Private — Sembukutty Sastha Kovil Internal Use Only
