import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/services/services.dart';

// ─── Services (singletons) ────────────────────────────────────────────────────
final authServiceProvider = Provider((_) => AuthService());
final staffServiceProvider = Provider((_) => StaffService());
final memberServiceProvider = Provider((_) => MemberService());
final openingBalanceServiceProvider = Provider((_) => OpeningBalanceService());
final transactionServiceProvider = Provider((_) => TransactionService());
final dashboardServiceProvider = Provider((_) => DashboardService());
final reportsServiceProvider = Provider((_) => ReportsService());
final documentsServiceProvider = Provider((_) => DocumentsService());
final backupServiceProvider = Provider((_) => BackupService());

// ─── Current Staff & Session ──────────────────────────────────────────────────
final currentStaffIdProvider = StateProvider<String?>((ref) => null);
final userRoleProvider = StateProvider<String>((ref) => 'staff'); // 'staff' or 'admin'

// ─── Staff List ───────────────────────────────────────────────────────────────
final staffListProvider = FutureProvider<List<StaffModel>>((ref) async {
  return ref.read(staffServiceProvider).getAll();
});

final pendingStaffListProvider = FutureProvider<List<StaffModel>>((ref) async {
  return ref.read(staffServiceProvider).getPending();
});

final setupStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(authServiceProvider).getSetupStatus();
});

// ─── Opening Balance ──────────────────────────────────────────────────────────
final openingBalanceProvider = FutureProvider<OpeningBalanceModel?>((ref) async {
  return ref.read(openingBalanceServiceProvider).get();
});

// ─── Dashboard ────────────────────────────────────────────────────────────────
final dashboardProvider = FutureProvider.family<DashboardData, String>((ref, staffId) async {
  return ref.read(dashboardServiceProvider).get(staffId);
});

// ─── My / All Transactions ───────────────────────────────────────────────────
final myTransactionsProvider = FutureProvider.family<List<TransactionModel>, String?>((ref, staffId) async {
  return ref.read(transactionServiceProvider).list(staffId: (staffId == null || staffId.isEmpty) ? null : staffId);
});

// ─── Documents Search ─────────────────────────────────────────────────────────
class DocumentsFilter {
  final String query;
  final String docType;
  final String? dateFrom;
  final String? dateTo;

  const DocumentsFilter({
    this.query = '',
    this.docType = 'all',
    this.dateFrom,
    this.dateTo,
  });

  @override
  bool operator ==(Object other) =>
      other is DocumentsFilter &&
      other.query == query &&
      other.docType == docType &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo;

  @override
  int get hashCode => Object.hash(query, docType, dateFrom, dateTo);
}

final documentsFilterProvider = StateProvider((_) => const DocumentsFilter());

final documentsProvider = FutureProvider.family<List<TransactionModel>, DocumentsFilter>((ref, filter) async {
  return ref.read(documentsServiceProvider).search(
        query: filter.query,
        docType: filter.docType,
        dateFrom: filter.dateFrom,
        dateTo: filter.dateTo,
      );
});

// ─── Global Accounting Invalidation Helper ────────────────────────────────────
void invalidateAllAccountingData(WidgetRef ref, [String? staffId]) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(myTransactionsProvider);
  if (staffId != null && staffId.isNotEmpty) {
    ref.invalidate(dashboardProvider(staffId));
    ref.invalidate(myTransactionsProvider(staffId));
  }
  ref.invalidate(dashboardProvider('admin'));
  ref.invalidate(dashboardProvider(''));
  ref.invalidate(myTransactionsProvider(null));
  ref.invalidate(documentsFilterProvider);
  ref.invalidate(openingBalanceProvider);
  ref.invalidate(staffListProvider);
}
