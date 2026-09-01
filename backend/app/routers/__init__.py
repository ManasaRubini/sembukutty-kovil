from app.routers.auth import router as auth
from app.routers.staff import router as staff
from app.routers.members import router as members
from app.routers.opening_balances import router as opening_balances
from app.routers.transactions import router as transactions
from app.routers.dashboard import router as dashboard
from app.routers.reports import router as reports
from app.routers.documents import router as documents
from app.routers.backup import router as backup

__all__ = [
    "auth", "staff", "members", "opening_balances",
    "transactions", "dashboard", "reports", "documents", "backup"
]
