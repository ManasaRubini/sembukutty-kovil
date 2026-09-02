from datetime import datetime
from typing import Optional
from pydantic import BaseModel


# ─── Staff ───────────────────────────────────────────────────────────────────

class StaffBase(BaseModel):
    name: str
    phone: Optional[str] = ""
    email: Optional[str] = ""


class StaffCreate(StaffBase):
    pin: Optional[str] = "1234"


class StaffUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    pin: Optional[str] = None
    is_active: Optional[bool] = None


class StaffOut(StaffBase):
    id: str
    is_active: bool
    is_approved: bool = True
    verification_code: Optional[str] = ""
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class AdminRegisterRequest(BaseModel):
    username: str
    password: str
    phone: Optional[str] = ""
    email: Optional[str] = ""


class StaffRegisterRequest(BaseModel):
    name: str
    phone: str
    email: Optional[str] = ""
    pin: str = "1234"


class SendPhoneOTPRequest(BaseModel):
    name: str
    phone: str
    email: str
    pin: str = "1234"


class VerifyPhoneOTPRequest(BaseModel):
    phone: str
    otp: str


class SendOTPReq(BaseModel):
    email: str
    name: Optional[str] = ""
    phone: Optional[str] = ""
    pin: Optional[str] = "1234"


class VerifyOTPReq(BaseModel):
    email: str
    otp: str


class ResendOTPReq(BaseModel):
    email: str


class ForgotPasswordSendOTPReq(BaseModel):
    email: str
    account_type: str = "member"  # "admin" or "member"
    staff_id: Optional[str] = None


class ForgotPasswordVerifyOTPReq(BaseModel):
    email: str
    otp: str


class ForgotPasswordResetReq(BaseModel):
    email: str
    account_type: str = "member"  # "admin" or "member"
    otp: str
    new_password_or_pin: str
    staff_id: Optional[str] = None


class ApproveStaffRequest(BaseModel):
    verification_code: Optional[str] = None


class SetupStatusOut(BaseModel):
    admin_registered: bool
    total_staff: int
    pending_approvals: int


class ResetAccountingRequest(BaseModel):
    bank_balance: float = 0.0
    cash_balance: float = 0.0


# ─── Member ──────────────────────────────────────────────────────────────────

class MemberBase(BaseModel):
    name: str
    phone: Optional[str] = ""
    address: Optional[str] = ""


class MemberCreate(MemberBase):
    pass


class MemberUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None


class MemberOut(MemberBase):
    id: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# ─── Opening Balance ─────────────────────────────────────────────────────────

class OpeningBalanceCreate(BaseModel):
    bank_balance: float = 0.0
    cash_balance: float = 0.0
    cash_holder_staff_id: str


class OpeningBalanceUpdate(BaseModel):
    bank_balance: Optional[float] = None
    cash_balance: Optional[float] = None
    cash_holder_staff_id: Optional[str] = None


class OpeningBalanceOut(BaseModel):
    id: str
    bank_balance: float
    cash_balance: float
    cash_holder_staff_id: Optional[str]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# ─── Transaction ─────────────────────────────────────────────────────────────

class TransactionCreate(BaseModel):
    staff_id: str
    type: str          # tax | donation | expense | transfer
    date: str          # YYYY-MM-DD
    amount: float
    mode: Optional[str] = None      # cash | bank
    member_id: Optional[str] = None
    member_name: Optional[str] = ""
    member_phone: Optional[str] = ""
    address: Optional[str] = ""
    purpose: Optional[str] = ""
    remarks: Optional[str] = ""
    paid_to: Optional[str] = ""
    direction: Optional[str] = None  # deposit | withdraw


class TransactionOut(BaseModel):
    id: str
    staff_id: Optional[str]
    type: str
    date: str
    amount: float
    mode: Optional[str]
    member_id: Optional[str]
    member_name: Optional[str]
    member_phone: Optional[str]
    address: Optional[str]
    purpose: Optional[str]
    remarks: Optional[str]
    paid_to: Optional[str]
    direction: Optional[str]
    serial_number: Optional[str]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# ─── Dashboard ───────────────────────────────────────────────────────────────

class DashboardOut(BaseModel):
    tax_collected: float
    donations: float
    expenses: float
    income: float
    net: float
    my_cash: float
    bank_balance: float
    total_cash: float
    grand_total: float
    recent_transactions: list[TransactionOut] = []


# ─── Reports ─────────────────────────────────────────────────────────────────

class CollectionSummary(BaseModel):
    total_tax: float
    total_donations: float
    total_cash: float
    total_bank: float
    total_collections: float
    rows: list[TransactionOut] = []


class ExpenseSummary(BaseModel):
    total_expenses: float
    total_cash: float
    total_bank: float
    rows: list[TransactionOut] = []


class StaffCashRow(BaseModel):
    staff_id: str
    staff_name: str
    cash_balance: float


class BalanceReport(BaseModel):
    opening_bank: float
    opening_cash: float
    bank_balance: float
    total_cash: float
    grand_total: float
    per_staff: list[StaffCashRow] = []


# ─── Auth ────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    username: str
    password: str


class StaffLoginRequest(BaseModel):
    staff_id: Optional[str] = None
    username: Optional[str] = None
    identifier: Optional[str] = None
    pin: str


class ResetVerifyRequest(BaseModel):
    account_type: str  # 'admin' or 'staff'
    identifier: str    # Phone number or Email address
    staff_id: Optional[str] = None


class ResetPasswordPINRequest(BaseModel):
    reset_token: str
    new_value: str  # New PIN for staff (e.g. 4 digits) or new password for admin


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str = "staff"
    staff_id: Optional[str] = None
    staff_name: Optional[str] = None


# ─── Backup ──────────────────────────────────────────────────────────────────

class BackupData(BaseModel):
    exported_at: str
    staff: list[dict]
    members: list[dict]
    opening_balance: Optional[dict]
    transactions: list[dict]
    document_sequences: list[dict]
