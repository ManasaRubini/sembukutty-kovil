# API Documentation — Sembukutty Sastha Kovil

Base URL: `http://localhost:8000/api`

## Authentication

### `POST /api/auth/login`
Authenticate admin user and return JWT token.
- **Request Body**:
  ```json
  {
    "username": "admin",
    "password": "kovil2024"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "access_token": "<jwt-token>",
    "token_type": "bearer"
  }
  ```

---

## Staff

### `GET /api/staff`
List all staff members.

### `POST /api/staff`
Create a billing staff member (max 5 active allowed).
- **Request Body**: `{"name": "Staff Name"}`

### `PUT /api/staff/{id}`
Update staff name or status (`is_active`).

### `DELETE /api/staff/{id}`
Deactivate staff member (soft delete).

---

## Members

### `GET /api/members`
List members. Query param `q` for search name or phone.

### `GET /api/members/search?q={query}`
Live search members matching name or phone. Preserves Tamil & English.

### `POST /api/members`
Add a new member.

---

## Opening Balances

### `GET /api/opening-balances`
Get temple opening bank and cash balances.

### `POST /api/opening-balances`
Set initial opening balances (first-time setup only).

### `PUT /api/opening-balances`
Update opening bank or cash balance.

---

## Transactions

### `POST /api/transactions`
Record a tax, donation, expense, or cash/bank transfer transaction.
- **Serial Numbers**: Automatically generated atomically (`R-00001`, `V-00001`, `T-00001`).

### `GET /api/transactions`
List transactions with optional filters (`staff_id`, `type`, `mode`, `date_from`, `date_to`).

### `DELETE /api/transactions/{id}`
Delete a transaction.

---

## Dashboard

### `GET /api/dashboard?staff_id={id}`
Returns aggregated accounting stats for current staff and overall temple balances.

---

## Reports

### `GET /api/reports/collections?scope=mine&date_from=YYYY-MM-DD&date_to=YYYY-MM-DD`
Tax and donation collections summary and itemized list.

### `GET /api/reports/expenses?scope=mine&date_from=YYYY-MM-DD&date_to=YYYY-MM-DD`
Expense summary and itemized list.

### `GET /api/reports/balances?scope=all&as_of=YYYY-MM-DD`
Bank balance, cash per staff, total cash, and grand total.

---

## Backup

### `GET /api/backup/export`
Export full database as JSON object.

### `POST /api/backup/import`
Import JSON backup file.
