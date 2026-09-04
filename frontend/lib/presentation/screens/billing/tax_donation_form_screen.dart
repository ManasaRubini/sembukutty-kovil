import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'success_screen.dart';

class TaxDonationFormScreen extends ConsumerStatefulWidget {
  final String type; // 'tax' | 'donation'
  final String staffId;

  const TaxDonationFormScreen({
    super.key,
    required this.type,
    required this.staffId,
  });

  @override
  ConsumerState<TaxDonationFormScreen> createState() => _TaxDonationFormScreenState();
}

class _TaxDonationFormScreenState extends ConsumerState<TaxDonationFormScreen> {
  final _searchCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: todayIso());

  MemberModel? _selectedMember;
  String? _selectedMode; // 'cash' | 'bank'
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'tax' ? 'Tax Collection' : 'Donation Collection';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontFamily: 'Fraunces', color: AppColors.gold100)),
        backgroundColor: AppColors.maroon900,
        iconTheme: const IconThemeData(color: AppColors.gold100),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _dateCtrl,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      _dateCtrl.text = picked.toIso8601String().substring(0, 10);
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text('Member (search by name or phone)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TypeAheadField<MemberModel>(
                  controller: _searchCtrl,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Type name or phone number',
                        prefixIcon: Icon(Icons.search, size: 20),
                      ),
                    );
                  },
                  suggestionsCallback: (pattern) async {
                    if (pattern.trim().length < 2) return [];
                    return await ref.read(memberServiceProvider).search(pattern);
                  },
                  itemBuilder: (context, member) {
                    return ListTile(
                      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: Text(member.phone, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    );
                  },
                  onSelected: (member) {
                    setState(() {
                      _selectedMember = member;
                      _searchCtrl.text = member.name;
                      _addressCtrl.text = member.address;
                      _phoneCtrl.text = member.phone;
                    });
                  },
                  emptyBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No member found — enter details manually below', style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                  ),
                ),
                if (_selectedMember != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.gold100,
                      border: Border.all(color: AppColors.gold300),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedMember!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            if (_selectedMember!.phone.isNotEmpty)
                              Text(_selectedMember!.phone, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedMember = null;
                              _searchCtrl.clear();
                              _addressCtrl.clear();
                              _phoneCtrl.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text('Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Address (auto-filled if member selected)'),
                ),
                const SizedBox(height: 14),
                const Text('Phone number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(hintText: 'Phone number'),
                ),
                const SizedBox(height: 14),
                const Text('Payment mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                PaymentModeSelector(
                  selected: _selectedMode,
                  onChanged: (mode) => setState(() => _selectedMode = mode),
                ),
                const SizedBox(height: 14),
                const Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: '0.00'),
                ),
                const SizedBox(height: 14),
                const Text('Purpose', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _purposeCtrl,
                  decoration: InputDecoration(
                    hintText: widget.type == 'tax' ? 'e.g. Annual Temple Tax 2026' : 'e.g. Donation for Annadhanam',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A serially numbered receipt is generated automatically for this entry.',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save entry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a payment mode')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final memberName = _selectedMember != null
          ? _selectedMember!.name
          : (_searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : 'Walk-in / Unspecified');

      final txn = await ref.read(transactionServiceProvider).create({
        'staff_id': widget.staffId,
        'type': widget.type,
        'date': _dateCtrl.text.trim(),
        'amount': amount,
        'mode': _selectedMode,
        'member_id': _selectedMember?.id,
        'member_name': memberName,
        'member_phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'purpose': _purposeCtrl.text.trim(),
      });

      invalidateAllAccountingData(ref, widget.staffId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(txn: txn, staffId: widget.staffId),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
