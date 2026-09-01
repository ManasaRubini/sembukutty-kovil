import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/stat_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onSwitchStaff;

  const SettingsScreen({super.key, required this.onSwitchStaff});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _newStaffCtrl = TextEditingController();
  final _apiUrlCtrl = TextEditingController(text: ApiConfig.baseUrl);

  String _exportFromDate = '';
  String _exportToDate = '';

  Future<void> _downloadExcelBackup({String? dateFrom, String? dateTo, String prefix = 'backup-1'}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Generating Excel backup workbook...'), duration: Duration(seconds: 2)),
      );
      final from = dateFrom ?? _exportFromDate;
      final to = dateTo ?? _exportToDate;

      final bytes = await ref.read(backupServiceProvider).exportExcelBytes(
        dateFrom: from,
        dateTo: to,
        prefix: prefix,
      );
      final todayStr = DateTime.now().toString().split(" ")[0];
      final filename = (from.isNotEmpty && to.isNotEmpty)
          ? '$prefix-$from-to-$to.xlsx'
          : '$prefix-$todayStr.xlsx';

      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: filename,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Excel export error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffId = ref.watch(currentStaffIdProvider);
    final userRole = ref.watch(userRoleProvider);
    final isAdmin = userRole == 'admin';
    final staffListAsync = ref.watch(staffListProvider);
    final obAsync = ref.watch(openingBalanceProvider);
    final dashAsync = staffId != null ? ref.watch(dashboardProvider(staffId)) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          const SectionTitle('Live balances'),
          dashAsync?.when(
                data: (d) => Row(
                  children: [
                    Expanded(child: StatCard(label: 'Bank balance', value: formatINR(d.bankBalance), variant: StatCardVariant.neutral)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(label: 'Total cash', value: formatINR(d.totalCash), variant: StatCardVariant.neutral)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(label: 'Grand total', value: formatINR(d.grandTotal), variant: StatCardVariant.closing)),
                  ],
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ) ??
              const SizedBox(),
          const SectionTitle('Billing members'),
          staffListAsync.when(
            data: (staffList) {
              final activeStaff = staffList.where((s) => s.isActive).toList();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeStaff.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = activeStaff[i];
                          final isAdmin = ref.watch(userRoleProvider) == 'admin';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Phone: ${s.phone.isNotEmpty ? s.phone : "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _renameStaff(s),
                                  child: const Text('Rename', style: TextStyle(fontSize: 12)),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.expense, size: 20),
                                    tooltip: 'Delete Billing Member (Admin Only)',
                                    onPressed: () => _confirmDeleteStaff(s),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (isAdmin) ...[
                        if (activeStaff.length < 10)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showAdminAddMemberDialog,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500, foregroundColor: AppColors.maroon900),
                              icon: const Icon(Icons.person_add_alt_1, size: 18),
                              label: const Text('Add Billing Member', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          )
                        else
                          const Text('Maximum limit of 10 billing members reached.', style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SectionTitle('Temple Records'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export to Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text(
                    'Select an optional date range (from date to date) to export formatted Excel records of receipts, expenses, devotees, and balances.',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: _exportFromDate),
                          decoration: const InputDecoration(
                            labelText: 'From Date (Optional)',
                            hintText: 'YYYY-MM-DD',
                            suffixIcon: Icon(Icons.calendar_today, size: 16),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setState(() => _exportFromDate = p.toIso8601String().substring(0, 10));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: _exportToDate),
                          decoration: const InputDecoration(
                            labelText: 'To Date (Optional)',
                            hintText: 'YYYY-MM-DD',
                            suffixIcon: Icon(Icons.calendar_today, size: 16),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setState(() => _exportToDate = p.toIso8601String().substring(0, 10));
                          },
                        ),
                      ),
                      if (_exportFromDate.isNotEmpty || _exportToDate.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear Date Filter',
                          onPressed: () => setState(() {
                            _exportFromDate = '';
                            _exportToDate = '';
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.income),
                        icon: const Icon(Icons.table_chart_outlined, size: 18),
                        label: Text(_exportFromDate.isNotEmpty && _exportToDate.isNotEmpty
                            ? 'Download Excel ($_exportFromDate to $_exportToDate)'
                            : 'Download Excel (.xlsx)'),
                        onPressed: _downloadExcelBackup,
                      ),                      
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (ref.watch(userRoleProvider) == 'admin') ...[
            const SectionTitle('Pending Member Approvals'),
            Consumer(
              builder: (context, ref, _) {
                final pendingAsync = ref.watch(pendingStaffListProvider);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.rule, color: AppColors.maroon700, size: 20),
                            SizedBox(width: 8),
                            Text('Pending Registration Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        pendingAsync.when(
                          data: (pendingList) {
                            if (pendingList.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, color: AppColors.income, size: 18),
                                    SizedBox(width: 8),
                                    Text('No pending member registration requests.', style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                                  ],
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pendingList.length,
                              separatorBuilder: (_, __) => const Divider(height: 12),
                              itemBuilder: (ctx, idx) {
                                final s = pendingList[idx];
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.gold100,
                                      child: Text(s.initial, style: const TextStyle(color: AppColors.maroon700, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                          Text('Phone: ${s.phone.isNotEmpty ? s.phone : "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await ref.read(staffServiceProvider).reject(s.id);
                                        ref.invalidate(pendingStaffListProvider);
                                        ref.invalidate(staffListProvider);
                                        ref.invalidate(setupStatusProvider);
                                      },
                                      child: const Text('Reject', style: TextStyle(color: AppColors.expense)),
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.income, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                      onPressed: () async {
                                        await ref.read(staffServiceProvider).approve(s.id);
                                        ref.invalidate(pendingStaffListProvider);
                                        ref.invalidate(staffListProvider);
                                        ref.invalidate(setupStatusProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${s.name} approved successfully!'), backgroundColor: AppColors.income),
                                          );
                                        }
                                      },
                                      child: const Text('Approve', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error loading pending list: $e', style: const TextStyle(color: AppColors.expense, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SectionTitle('Admin Data Control'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.expense, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Reset Billing & Transaction Receipts',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.expense),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Deletes all receipts, vouchers, transfer notes, and resets document serial numbers to 0. An Excel backup (backup-1-[date].xlsx) will be automatically downloaded before reset.',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('Reset All Billing Data (Keep Devotees)'),
                      onPressed: _confirmResetAccountingData,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SectionTitle('Session & Account'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: const BorderSide(color: AppColors.expense),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.expense),
                  onPressed: widget.onSwitchStaff,
                  label: const Text('Logout / Switch Billing Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editOpening(String type, double currentVal) async {
    final ctrl = TextEditingController(text: currentVal.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Opening ${type == "bank" ? "Bank" : "Cash"} Balance'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null) {
                if (type == 'bank') {
                  await ref.read(openingBalanceServiceProvider).update(bankBalance: val);
                } else {
                  await ref.read(openingBalanceServiceProvider).update(cashBalance: val);
                }
                ref.invalidate(openingBalanceProvider);
                final staffId = ref.read(currentStaffIdProvider);
                if (staffId != null) ref.invalidate(dashboardProvider(staffId));
              }
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameStaff(StaffModel staff) async {
    final ctrl = TextEditingController(text: staff.name);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Billing Member'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await ref.read(staffServiceProvider).update(staff.id, name: name);
                ref.invalidate(staffListProvider);
              }
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteStaff(StaffModel staff) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.expense),
            const SizedBox(width: 8),
            Text('Delete ${staff.name}?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${staff.name}? They will no longer be able to log in to the temple billing system.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Member'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(staffServiceProvider).deactivate(staff.id);
        ref.invalidate(staffListProvider);
        ref.invalidate(pendingStaffListProvider);
        ref.invalidate(setupStatusProvider);

        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('${staff.name} deleted successfully.'),
            backgroundColor: AppColors.expense,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Error deleting member: $e')));
      }
    }
  }

  Future<void> _showAdminAddMemberDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    String? formError;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1, color: AppColors.maroon700),
                SizedBox(width: 8),
                Text('Add Billing Member', style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter new billing member details to create their account:', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                    const SizedBox(height: 14),
                    if (formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.expenseBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(formError!, style: const TextStyle(color: AppColors.expense, fontSize: 12.5)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline, size: 20)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Mobile Phone Number *', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email Address *', prefixIcon: Icon(Icons.email_outlined, size: 20)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(labelText: '4-digit Login PIN *', prefixIcon: Icon(Icons.lock_outline, size: 20), counterText: ''),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final pin = pinCtrl.text.trim();

                        if (name.isEmpty || phone.isEmpty || email.isEmpty || pin.isEmpty) {
                          setDialogState(() => formError = 'Name, Phone Number, Email, and PIN are required.');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          formError = null;
                        });

                        try {
                          await ref.read(staffServiceProvider).create(
                                name,
                                phone: phone,
                                email: email,
                                pin: pin,
                              );
                          ref.invalidate(staffListProvider);

                          if (!mounted) return;
                          Navigator.of(dialogCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name added as billing member successfully!'),
                              backgroundColor: AppColors.income,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            formError = e.toString();
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Member'),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _confirmResetAccountingData() async {
    final bankCtrl = TextEditingController(text: '0');
    final cashCtrl = TextEditingController(text: '0');
    final confirmCtrl = TextEditingController();
    String? dialogError;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.expense),
                SizedBox(width: 8),
                Text('Reset All Billing Data?', style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This action will permanently delete all tax receipts, donation receipts, payment vouchers, and reset document numbers to R-00000.',
                      style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.incomeBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.income)),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.income, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your list of 634+ Devotees (members) will NOT be deleted.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.income),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.table_chart_outlined, color: AppColors.income, size: 18),
                      label: const Text('Export Excel Backup First (.xlsx)', style: TextStyle(color: AppColors.income, fontSize: 12.5, fontWeight: FontWeight.bold)),
                      onPressed: _downloadExcelBackup,
                    ),
                    const SizedBox(height: 14),
                    const Text('Set Initial Opening Balances for Reset:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bankCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Initial Opening Bank Balance (₹)',
                        prefixIcon: Icon(Icons.account_balance, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cashCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Initial Opening Cash Balance (₹)',
                        prefixIcon: Icon(Icons.payments_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (dialogError != null) ...[
                      Text(dialogError!, style: const TextStyle(color: AppColors.expense, fontSize: 12.5)),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: confirmCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Type RESET to confirm',
                        hintText: 'RESET',
                        prefixIcon: Icon(Icons.security, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final val = confirmCtrl.text.trim();
                        if (val != 'RESET') {
                          setDialogState(() => dialogError = 'Please type RESET in capital letters to confirm.');
                          return;
                        }

                        final bankVal = double.tryParse(bankCtrl.text.trim()) ?? 0.0;
                        final cashVal = double.tryParse(cashCtrl.text.trim()) ?? 0.0;

                        setDialogState(() {
                          isSubmitting = true;
                          dialogError = null;
                        });

                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          // Automatically download Excel backup named backup-1-[date].xlsx before reset
                          try {
                            await _downloadExcelBackup(prefix: 'backup-1');
                          } catch (_) {}

                          final res = await ref.read(backupServiceProvider).resetAccountingData(
                                bankBalance: bankVal,
                                cashBalance: cashVal,
                              );
                          invalidateAllAccountingData(ref);

                          if (!mounted) return;
                          Navigator.of(dialogCtx).pop();

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Data reset successfully.'),
                              backgroundColor: AppColors.income,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = e.toString();
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Reset'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadBackup() async {
    try {
      final data = await ref.read(backupServiceProvider).export();
      final jsonStr = jsonEncode(data);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('JSON Backup Data'),
          content: SingleChildScrollView(child: Text(jsonStr, style: const TextStyle(fontSize: 10, fontFamily: 'monospace'))),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
