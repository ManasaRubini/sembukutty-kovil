import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class DevoteesScreen extends ConsumerStatefulWidget {
  const DevoteesScreen({super.key});

  @override
  ConsumerState<DevoteesScreen> createState() => _DevoteesScreenState();
}

class _DevoteesScreenState extends ConsumerState<DevoteesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Add Devotee Modal ──────────────────────────────────────────────────────
  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSubmitting = false;
    String? errorText;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1, color: AppColors.maroon700),
                SizedBox(width: 8),
                Text('Add New Devotee', style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.expenseBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(errorText!, style: const TextStyle(color: AppColors.expense, fontSize: 12.5)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const Text('Enter devotee details to add them to Kovil records:', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Devotee Full Name *',
                        hintText: 'e.g. கார்த்திக் / Ramaswamy',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number',
                        hintText: 'e.g. 9876543210',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address / Town',
                        hintText: 'e.g. தூத்துக்குடி',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => errorText = 'Devotee name is required.');
                          return;
                        }
                        setDialogState(() {
                          isSubmitting = true;
                          errorText = null;
                        });

                        try {
                          final member = await ref.read(memberServiceProvider).create(
                                name: name,
                                phone: phoneCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                              );
                          ref.invalidate(devoteeListProvider);
                          if (!ctx.mounted) return;
                          Navigator.of(dialogCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Devotee "${member.name}" added successfully!')),
                          );
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorText = e.toString();
                          });
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: const Text('Save Devotee'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Edit Devotee Modal ─────────────────────────────────────────────────────
  Future<void> _showEditDialog(MemberModel member) async {
    final nameCtrl = TextEditingController(text: member.name);
    final phoneCtrl = TextEditingController(text: member.phone);
    final addressCtrl = TextEditingController(text: member.address);
    bool isSubmitting = false;
    String? errorText;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.maroon700),
                SizedBox(width: 8),
                Text('Edit Devotee Details', style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.expenseBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(errorText!, style: const TextStyle(color: AppColors.expense, fontSize: 12.5)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Devotee Full Name *',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address / Town',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => errorText = 'Devotee name is required.');
                          return;
                        }
                        setDialogState(() {
                          isSubmitting = true;
                          errorText = null;
                        });

                        try {
                          await ref.read(memberServiceProvider).update(
                                member.id,
                                name: name,
                                phone: phoneCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                              );
                          ref.invalidate(devoteeListProvider);
                          if (!ctx.mounted) return;
                          Navigator.of(dialogCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Devotee details updated successfully!')),
                          );
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorText = e.toString();
                          });
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18),
                label: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Delete Devotee Confirmation ───────────────────────────────────────────
  Future<void> _showDeleteConfirm(MemberModel member) async {
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.expense),
                SizedBox(width: 8),
                Text('Delete Devotee?'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete "${member.name}" from Kovil records?',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                if (member.phone.isNotEmpty || member.address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (member.phone.isNotEmpty) 'Phone: ${member.phone}',
                      if (member.address.isNotEmpty) 'Address: ${member.address}',
                    ].join('\n'),
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          await ref.read(memberServiceProvider).delete(member.id);
                          ref.invalidate(devoteeListProvider);
                          if (!ctx.mounted) return;
                          Navigator.of(dialogCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Devotee "${member.name}" deleted.')),
                          );
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Delete failed: ${e.toString()}')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, foregroundColor: Colors.white),
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.delete_forever, size: 18),
                label: const Text('Delete Devotee'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devoteesAsync = ref.watch(devoteeListProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text(
          'Devotee Details & Records',
          style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.gold100),
        ),
        backgroundColor: AppColors.maroon900,
        iconTheme: const IconThemeData(color: AppColors.gold100),
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.maroon700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Devotee', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Action Header Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      ref.read(devoteeQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Phone, or Town...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref.read(devoteeQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Devotees List
          Expanded(
            child: devoteesAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 48, color: AppColors.inkSoft),
                        const SizedBox(height: 12),
                        const Text('No devotees found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Tap "+ Add New" above to add a Kovil devotee.', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text('Add Devotee Now'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = list[index];
                    final initial = member.name.isNotEmpty ? member.name.characters.first : 'D';

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.maroon700,
                              child: Text(
                                initial,
                                style: const TextStyle(color: AppColors.gold100, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.ink),
                                  ),
                                  if (member.phone.isNotEmpty || member.address.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (member.phone.isNotEmpty) '📞 ${member.phone}',
                                        if (member.address.isNotEmpty) '📍 ${member.address}',
                                      ].join('   '),
                                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.maroon700, size: 20),
                                  tooltip: 'Edit Devotee',
                                  onPressed: () => _showEditDialog(member),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.expense, size: 20),
                                  tooltip: 'Delete Devotee',
                                  onPressed: () => _showDeleteConfirm(member),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load devotees', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.refresh(devoteeListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
