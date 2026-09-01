// ─── Staff Model ──────────────────────────────────────────────────────────────
class StaffModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isActive;
  final bool isApproved;
  final String verificationCode;

  const StaffModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    required this.isActive,
    this.isApproved = true,
    this.verificationCode = '',
  });

  factory StaffModel.fromJson(Map<String, dynamic> j) => StaffModel(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String? ?? '',
        isActive: j['is_active'] as bool? ?? true,
        isApproved: j['is_approved'] as bool? ?? true,
        verificationCode: j['verification_code'] as String? ?? '',
      );

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'is_active': isActive,
        'is_approved': isApproved,
        'verification_code': verificationCode,
      };
}

// ─── Member Model ─────────────────────────────────────────────────────────────
class MemberModel {
  final String id;
  final String name;
  final String phone;
  final String address;

  const MemberModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory MemberModel.fromJson(Map<String, dynamic> j) => MemberModel(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String? ?? '',
        address: j['address'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
      };
}

// ─── Opening Balance ──────────────────────────────────────────────────────────
class OpeningBalanceModel {
  final String id;
  final double bankBalance;
  final double cashBalance;
  final String? cashHolderStaffId;

  const OpeningBalanceModel({
    required this.id,
    required this.bankBalance,
    required this.cashBalance,
    this.cashHolderStaffId,
  });

  factory OpeningBalanceModel.fromJson(Map<String, dynamic> j) => OpeningBalanceModel(
        id: j['id'] as String,
        bankBalance: (j['bank_balance'] as num).toDouble(),
        cashBalance: (j['cash_balance'] as num).toDouble(),
        cashHolderStaffId: j['cash_holder_staff_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bank_balance': bankBalance,
        'cash_balance': cashBalance,
        'cash_holder_staff_id': cashHolderStaffId,
      };
}

// ─── Transaction Model ────────────────────────────────────────────────────────
class TransactionModel {
  final String id;
  final String? staffId;
  final String type;     // tax | donation | expense | transfer
  final String date;     // YYYY-MM-DD
  final double amount;
  final String? mode;    // cash | bank
  final String? memberId;
  final String memberName;
  final String memberPhone;
  final String address;
  final String purpose;
  final String remarks;
  final String paidTo;
  final String? direction;  // deposit | withdraw
  final String? serialNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    this.staffId,
    required this.type,
    required this.date,
    required this.amount,
    this.mode,
    this.memberId,
    this.memberName = '',
    this.memberPhone = '',
    this.address = '',
    this.purpose = '',
    this.remarks = '',
    this.paidTo = '',
    this.direction,
    this.serialNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
        id: j['id'] as String,
        staffId: j['staff_id'] as String?,
        type: j['type'] as String,
        date: j['date'] as String,
        amount: (j['amount'] as num).toDouble(),
        mode: j['mode'] as String?,
        memberId: j['member_id'] as String?,
        memberName: j['member_name'] as String? ?? '',
        memberPhone: j['member_phone'] as String? ?? '',
        address: j['address'] as String? ?? '',
        purpose: j['purpose'] as String? ?? '',
        remarks: j['remarks'] as String? ?? '',
        paidTo: j['paid_to'] as String? ?? '',
        direction: j['direction'] as String?,
        serialNumber: j['serial_number'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'staff_id': staffId,
        'type': type,
        'date': date,
        'amount': amount,
        'mode': mode,
        'member_id': memberId,
        'member_name': memberName,
        'member_phone': memberPhone,
        'address': address,
        'purpose': purpose,
        'remarks': remarks,
        'paid_to': paidTo,
        'direction': direction,
        'serial_number': serialNumber,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  String get displayDescription {
    switch (type) {
      case 'expense':
        return remarks.isNotEmpty ? remarks : '—';
      case 'transfer':
        return direction == 'deposit' ? 'Cash deposited to bank' : 'Cash withdrawn from bank';
      default:
        return memberName.isNotEmpty ? memberName : 'Walk-in / Unspecified';
    }
  }

  String get typeLabel {
    switch (type) {
      case 'tax': return 'Tax';
      case 'donation': return 'Donation';
      case 'expense': return 'Expense';
      case 'transfer': return 'Transfer';
      default: return type;
    }
  }

  String get documentLabel {
    if (type == 'expense') return 'Voucher';
    if (type == 'transfer') return 'Transfer Note';
    return 'Receipt';
  }
}

// ─── Dashboard Model ──────────────────────────────────────────────────────────
class DashboardData {
  final double taxCollected;
  final double donations;
  final double expenses;
  final double income;
  final double net;
  final double myCash;
  final double bankBalance;
  final double totalCash;
  final double grandTotal;
  final List<TransactionModel> recentTransactions;

  const DashboardData({
    required this.taxCollected,
    required this.donations,
    required this.expenses,
    required this.income,
    required this.net,
    required this.myCash,
    required this.bankBalance,
    required this.totalCash,
    required this.grandTotal,
    required this.recentTransactions,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        taxCollected: (j['tax_collected'] as num).toDouble(),
        donations: (j['donations'] as num).toDouble(),
        expenses: (j['expenses'] as num).toDouble(),
        income: (j['income'] as num).toDouble(),
        net: (j['net'] as num).toDouble(),
        myCash: (j['my_cash'] as num).toDouble(),
        bankBalance: (j['bank_balance'] as num).toDouble(),
        totalCash: (j['total_cash'] as num).toDouble(),
        grandTotal: (j['grand_total'] as num).toDouble(),
        recentTransactions: (j['recent_transactions'] as List? ?? [])
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'tax_collected': taxCollected,
        'donations': donations,
        'expenses': expenses,
        'income': income,
        'net': net,
        'my_cash': myCash,
        'bank_balance': bankBalance,
        'total_cash': totalCash,
        'grand_total': grandTotal,
        'recent_transactions': recentTransactions.map((t) => t.toJson()).toList(),
      };
}
