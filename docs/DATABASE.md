# Database Schema — Sembukutty Sastha Kovil

Database: **PostgreSQL 16** with UTF-8 encoding (supporting Tamil & English text).

## Entity Relationship Diagram & Tables

```
+-------------------+       +-----------------------+
|       staff       |       |        members        |
+-------------------+       +-----------------------+
| id (PK)           |<---+  | id (PK)               |<---+
| name              |    |  | name                  |    |
| is_active         |    |  | phone                 |    |
| created_at        |    |  | address               |    |
+-------------------+    |  +-----------------------+    |
                         |                               |
                         |  +-----------------------+    |
                         |  |     transactions      |    |
                         |  +-----------------------+    |
                         +--| staff_id (FK)         |    |
                            | type                  |    |
                            | date                  |    |
                            | amount                |    |
                            | mode                  |    |
                            +--| member_id (FK)     |----+
                            | member_name           |
                            | member_phone          |
                            | address               |
                            | purpose / remarks     |
                            | paid_to               |
                            | direction             |
                            | serial_number         |
                            +-----------------------+
```

### 1. `staff`
- `id` (UUID string, PK)
- `name` (VARCHAR 255)
- `is_active` (BOOLEAN, default true)
- `created_at` / `updated_at` (TIMESTAMPTZ)

### 2. `members`
- `id` (UUID string, PK)
- `name` (VARCHAR 512, indexed) — Tamil / English name
- `phone` (VARCHAR 100)
- `address` (TEXT) — Tamil / English address
- `created_at` / `updated_at` (TIMESTAMPTZ)

### 3. `opening_balances`
- `id` (UUID string, PK)
- `bank_balance` (NUMERIC 15,2) — Temple shared bank balance
- `cash_balance` (NUMERIC 15,2) — Initial opening cash
- `cash_holder_staff_id` (FK -> `staff.id`)
- `created_at` / `updated_at` (TIMESTAMPTZ)

### 4. `transactions`
- `id` (UUID string, PK)
- `staff_id` (FK -> `staff.id`)
- `type` (`tax` | `donation` | `expense` | `transfer`)
- `date` (DATE)
- `amount` (NUMERIC 15,2)
- `mode` (`cash` | `bank`)
- `member_id` (FK -> `members.id`, nullable)
- `member_name` / `member_phone` / `address`
- `purpose` / `remarks` / `paid_to`
- `direction` (`deposit` | `withdraw`, for transfers)
- `serial_number` (VARCHAR 20, indexed: `R-00001`, `V-00001`, `T-00001`)
- `created_at` / `updated_at` (TIMESTAMPTZ)

### 5. `document_sequences`
- `id` (INTEGER, PK)
- `document_type` (VARCHAR 20, UNIQUE: `receipt`, `voucher`, `transfer`)
- `current_number` (INTEGER)
