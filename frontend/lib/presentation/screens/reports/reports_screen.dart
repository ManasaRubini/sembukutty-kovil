import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _scope = 'mine'; // 'mine' | 'all' | staffId
  String _reportTab = 'collections'; // 'collections' | 'expenses' | 'balance'
  String _dateFrom = firstOfMonth();
  String _dateTo = todayIso();
  String _asOf = todayIso();

  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = ref.read(userRoleProvider);
      if (role == 'admin') {
        setState(() => _scope = 'all');
      }
      _runReport();
    });
  }

  Future<void> _runReport() async {
    final role = ref.read(userRoleProvider);
    final currentStaffId = role == 'admin' ? null : ref.read(currentStaffIdProvider);
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data;
      if (_reportTab == 'collections') {
        data = await ref.read(reportsServiceProvider).collections(
              scope: _scope,
              staffId: currentStaffId,
              dateFrom: _dateFrom,
              dateTo: _dateTo,
            );
      } else if (_reportTab == 'expenses') {
        data = await ref.read(reportsServiceProvider).expenses(
              scope: _scope,
              staffId: currentStaffId,
              dateFrom: _dateFrom,
              dateTo: _dateTo,
            );
      } else {
        data = await ref.read(reportsServiceProvider).balances(
              scope: _scope,
              staffId: currentStaffId,
              dateFrom: _dateFrom,
              dateTo: _dateTo,
            );
      }
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStaffId = ref.watch(currentStaffIdProvider);
    final staffListAsync = ref.watch(staffListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reports',
            style: TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          // Filter bar (Unified Date Range for all tabs)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: _dateFrom),
                      decoration: const InputDecoration(labelText: 'From date', suffixIcon: Icon(Icons.calendar_today, size: 16)),
                      readOnly: true,
                      onTap: () async {
                        final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (p != null) setState(() => _dateFrom = p.toIso8601String().substring(0, 10));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: _dateTo),
                      decoration: const InputDecoration(labelText: 'To date', suffixIcon: Icon(Icons.calendar_today, size: 16)),
                      readOnly: true,
                      onTap: () async {
                        final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (p != null) setState(() => _dateTo = p.toIso8601String().substring(0, 10));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _runReport,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500, foregroundColor: AppColors.maroon900),
                    child: const Text('Generate'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Scope pills
          staffListAsync.when(
            data: (staffList) {
              final role = ref.watch(userRoleProvider);
              final isAdmin = role == 'admin';
              final visibleStaff = isAdmin
                  ? staffList
                  : staffList.where((s) => s.id != currentStaffId).toList();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (!isAdmin)
                      _Pill(
                        'Me',
                        selected: _scope == 'mine',
                        onTap: () {
                          setState(() => _scope = 'mine');
                          _runReport();
                        },
                      ),
                    _Pill(
                      'Combined — All members',
                      selected: _scope == 'all',
                      onTap: () {
                        setState(() => _scope = 'all');
                        _runReport();
                      },
                    ),
                    if (isAdmin)
                      _Pill(
                        'Admin',
                        selected: _scope == 'mine',
                        onTap: () {
                          setState(() => _scope = 'mine');
                          _runReport();
                        },
                      ),
                    ...visibleStaff.map(
                      (s) => _Pill(
                        s.name,
                        selected: _scope == s.id,
                        onTap: () {
                          setState(() => _scope = s.id);
                          _runReport();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 14),
          // Report tabs
          Row(
            children: [
              _RTab('Collections', selected: _reportTab == 'collections', onTap: () { setState(() => _reportTab = 'collections'); _runReport(); }),
              const SizedBox(width: 16),
              _RTab('Expenses', selected: _reportTab == 'expenses', onTap: () { setState(() => _reportTab = 'expenses'); _runReport(); }),
              const SizedBox(width: 16),
              _RTab('Balance sheet', selected: _reportTab == 'balance', onTap: () { setState(() => _reportTab = 'balance'); _runReport(); }),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          // Report body
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_reportData == null)
            const Center(child: Text('Click Generate to view report'))
          else
            _buildReportBody(),
        ],
      ),
    );
  }

  Widget _buildReportBody() {
    if (_reportTab == 'collections') {
      final rows = (_reportData!['rows'] as List? ?? []);
      return Column(
        children: [
          if (rows.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('No collections in this period.', style: TextStyle(color: AppColors.inkSoft)))
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return ListTile(
                    dense: true,
                    title: Text(r['member_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${formatDate(r['date'])} · ${r['mode'] == "cash" ? "Cash" : "Bank"}'),
                    trailing: Text(formatINR(_asDouble(r['amount'])), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.income)),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Line('Total Tax collected', formatINR(_asDouble(_reportData!['total_tax']))),
                  _Line('Total Donations collected', formatINR(_asDouble(_reportData!['total_donations']))),
                  _Line('— via Cash', formatINR(_asDouble(_reportData!['total_cash'])), isSub: true),
                  _Line('— via Bank transfer', formatINR(_asDouble(_reportData!['total_bank'])), isSub: true),
                  const Divider(),
                  _Line('Total Collections', formatINR(_asDouble(_reportData!['total_collections'])), isTotal: true),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_reportTab == 'expenses') {
      final rows = (_reportData!['rows'] as List? ?? []);
      return Column(
        children: [
          if (rows.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('No expenses in this period.', style: TextStyle(color: AppColors.inkSoft)))
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return ListTile(
                    dense: true,
                    title: Text(r['remarks'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${formatDate(r['date'])} · Paid to: ${r['paid_to'] ?? "—"}'),
                    trailing: Text(formatINR(_asDouble(r['amount'])), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense)),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Line('— from Cash', formatINR(_asDouble(_reportData!['total_cash'])), isSub: true),
                  _Line('— from Bank', formatINR(_asDouble(_reportData!['total_bank'])), isSub: true),
                  const Divider(),
                  _Line('Total Expenses', formatINR(_asDouble(_reportData!['total_expenses'])), isTotal: true, color: AppColors.expense),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Balance sheet
      final perStaff = (_reportData!['per_staff'] as List? ?? []);
      final openingCash = _asDouble(_reportData!['opening_cash']);
      final cashCollections = _asDouble(_reportData!['cash_collections']);
      final cashExpenses = _asDouble(_reportData!['cash_expenses']);
      final cashDeposited = _asDouble(_reportData!['cash_deposited']);
      final cashWithdrawn = _asDouble(_reportData!['cash_withdrawn']);
      final totalCash = _asDouble(_reportData!['total_cash']);
      final openingBank = _asDouble(_reportData!['opening_bank']);
      final bankBalance = _asDouble(_reportData!['bank_balance']);
      final grandTotal = _asDouble(_reportData!['grand_total']);

      return Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Bank'),
                  _Line('Opening bank balance (${formatDate(_dateFrom)})', formatINR(openingBank)),
                  _Line('Closing Bank Balance (${formatDate(_dateTo)})', formatINR(bankBalance), isTotal: true),
                  const Divider(height: 24),
                  const SectionTitle('Cash Flow & Balance'),
                  _Line('Opening cash balance (${formatDate(_dateFrom)})', formatINR(openingCash)),
                  _Line('+ Tax & Donations (Cash)', formatINR(cashCollections), isSub: true),
                  _Line('+ Cash Withdrawn from Bank', formatINR(cashWithdrawn), isSub: true),
                  _Line('- Expenses (Cash)', formatINR(cashExpenses), isSub: true),
                  _Line('- Cash Deposited to Bank', formatINR(cashDeposited), isSub: true),
                  const Divider(height: 16),
                  _Line(
                    _scope == 'all'
                        ? 'Closing Cash Balance — All members (${formatDate(_dateTo)})'
                        : 'Closing Cash in Hand (${formatDate(_dateTo)} EOD)',
                    formatINR(totalCash),
                    isTotal: true,
                    color: AppColors.maroon900,
                  ),
                  if (_scope == 'all') ...[
                    const Divider(height: 24),
                    const SectionTitle('Grand Total'),
                    _Line('Bank + Cash (${formatDate(_dateTo)} EOD)', formatINR(grandTotal), isTotal: true, color: AppColors.income),
                  ],
                ],
              ),
            ),
          ),
          if (perStaff.isNotEmpty && _scope == 'all') ...[
            const SizedBox(height: 12),
            const SectionTitle('Closing cash in hand — by billing member'),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: perStaff.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = perStaff[i];
                  return ListTile(
                    title: Text(s['staff_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(formatINR(_asDouble(s['cash_balance'])), style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ],
        ],
      );
    }
  }

  double _asDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String val;
  final bool isSub;
  final bool isTotal;
  final Color? color;

  const _Line(this.label, this.val, {this.isSub = false, this.isTotal = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSub ? 3 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSub ? 12.5 : 14,
              color: isSub ? AppColors.inkSoft : AppColors.ink,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.maroon700 : AppColors.paper,
            border: Border.all(color: selected ? AppColors.maroon700 : AppColors.line),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.inkSoft),
          ),
        ),
      ),
    );
  }
}

class _RTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RTab(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.gold500 : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? AppColors.maroon700 : AppColors.inkSoft,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}
