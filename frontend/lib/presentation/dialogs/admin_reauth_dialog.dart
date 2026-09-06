import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class AdminReauthDialog extends ConsumerStatefulWidget {
  const AdminReauthDialog({super.key});

  @override
  ConsumerState<AdminReauthDialog> createState() => _AdminReauthDialogState();
}

class _AdminReauthDialogState extends ConsumerState<AdminReauthDialog> {
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Username and password are required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ref.read(authServiceProvider).adminLogin(username, password);
      final token = res['access_token'] as String? ?? '';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.kIsLoggedIn, true);
      await prefs.setString(AppConstants.kUserRole, 'admin');
      await prefs.setString('auth_token', token);

      ref.read(userRoleProvider.notifier).state = 'admin';
      
      // Invalidate relevant providers to refresh data with the new token
      ref.invalidate(pendingStaffListProvider);
      ref.invalidate(setupStatusProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: AppColors.maroon900, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Access Required',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.maroon900,
                        ),
                      ),
                      Text(
                        'Enter Admin password to authorize',
                        style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.expenseBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.expense, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin Username',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                prefixIcon: Icon(Icons.lock_outline, size: 20),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Authorize', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> promptAdminReauth(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const AdminReauthDialog(),
  );
  return result ?? false;
}
