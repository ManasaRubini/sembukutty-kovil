import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/offline_storage.dart';
import '../../providers/providers.dart';
import '../widgets/temple_header.dart';
import 'main_shell.dart';

class StaffSelectionScreen extends ConsumerStatefulWidget {
  const StaffSelectionScreen({super.key});

  @override
  ConsumerState<StaffSelectionScreen> createState() => _StaffSelectionScreenState();
}

class _StaffSelectionScreenState extends ConsumerState<StaffSelectionScreen> {
  int _selectedTab = 0; // 0 = Staff Login, 1 = Admin Login

  // Admin login controllers
  final _adminUserCtrl = TextEditingController(text: 'admin');
  final _adminPassCtrl = TextEditingController(text: 'kovil2024');

  bool _isAdminLoading = false;
  String? _adminError;

  @override
  void dispose() {
    _adminUserCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  // ─── PIN Dialog ─────────────────────────────────────────────────────────────
  Future<void> _onStaffCardTap(StaffModel staff) async {
    final pinCtrl = TextEditingController();
    String? pinError;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.maroon700,
                  child: Text(
                    staff.initial,
                    style: const TextStyle(color: AppColors.gold100, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Login as ${staff.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter your 4-digit PIN to continue:', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'PIN (Default: 1234)',
                    errorText: pinError,
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _showForgotDialog(staff: staff, accountType: 'member');
                    },
                    child: const Text(
                      'Forgot PIN? Reset via Email OTP',
                      style: TextStyle(fontSize: 12, color: AppColors.maroon700),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final pin = pinCtrl.text.trim();
                        if (pin.isEmpty) {
                          setDialogState(() => pinError = 'Please enter your PIN');
                          return;
                        }
                        setDialogState(() {
                          isSubmitting = true;
                          pinError = null;
                        });

                        final nav = Navigator.of(context);
                        try {
                          final res = await ref.read(authServiceProvider).staffLogin(staff.id, pin);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(AppConstants.kCurrentStaffId, staff.id);
                          await prefs.setString('auth_token', res['access_token'] ?? '');
                          await prefs.setString('user_role', 'staff');

                          ref.read(currentStaffIdProvider.notifier).state = staff.id;
                          ref.read(userRoleProvider.notifier).state = 'staff';

                          if (!mounted) return;
                          Navigator.of(dialogCtx).pop();
                          nav.pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainShell()),
                          );
                        } catch (e) {
                          // Offline login support: allow member login if server is unreachable
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(AppConstants.kCurrentStaffId, staff.id);
                          await prefs.setString('user_role', 'staff');

                          ref.read(currentStaffIdProvider.notifier).state = staff.id;
                          ref.read(userRoleProvider.notifier).state = 'staff';

                          if (!mounted) return;
                          Navigator.of(dialogCtx).pop();
                          nav.pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainShell()),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Login'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Forgot Password / PIN via Email OTP Modal ──────────────────────────────
  Future<void> _showForgotDialog({StaffModel? staff, String accountType = 'member'}) async {
    final emailCtrl = TextEditingController(text: staff?.email ?? '');
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    int step = 1; // 1 = Enter Email, 2 = Enter OTP, 3 = Reset Password / PIN
    String? formError;
    bool isSubmitting = false;
    int cooldownSeconds = 0;
    Timer? cooldownTimer;

    void startCooldownTimer(int seconds, Function setDialogState) {
      cooldownTimer?.cancel();
      setDialogState(() => cooldownSeconds = seconds);
      cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (cooldownSeconds <= 1) {
          t.cancel();
          setDialogState(() => cooldownSeconds = 0);
        } else {
          setDialogState(() => cooldownSeconds--);
        }
      });
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset, color: AppColors.maroon700),
                const SizedBox(width: 8),
                Text(
                  accountType == 'admin' ? 'Reset Admin Password' : 'Reset Member PIN',
                  style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.expenseBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(formError!, style: const TextStyle(color: AppColors.expense, fontSize: 12.5)),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (step == 1) ...[
                      Text(
                        accountType == 'admin'
                            ? 'Enter your Admin email address to receive a 6-digit password reset OTP:'
                            : 'Enter registered email address for ${staff?.name ?? "member"} to receive a 6-digit PIN reset OTP:',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Registered Email Address *',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                    ] else if (step == 2) ...[
                      Center(
                        child: Column(
                          children: [
                            const Text('We\'ve sent a 6-digit reset code to', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                            const SizedBox(height: 4),
                            Text(
                              emailCtrl.text.trim(),
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.maroon700),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: otpCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                              decoration: InputDecoration(
                                hintText: '• • • • • •',
                                hintStyle: const TextStyle(letterSpacing: 8, color: AppColors.inkSoft),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      step = 1;
                                      formError = null;
                                      otpCtrl.clear();
                                    });
                                  },
                                  child: const Text('Change Email', style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                                ),
                                TextButton(
                                  onPressed: (cooldownSeconds > 0 || isSubmitting)
                                      ? null
                                      : () async {
                                          setDialogState(() {
                                            isSubmitting = true;
                                            formError = null;
                                          });
                                          try {
                                            final res = await ref.read(authServiceProvider).forgotPasswordSendOtp(
                                                  email: emailCtrl.text.trim(),
                                                  accountType: accountType,
                                                  staffId: staff?.id,
                                                );
                                            startCooldownTimer(res['cooldown_seconds'] ?? 30, setDialogState);
                                            setDialogState(() {
                                              isSubmitting = false;
                                              formError = null;
                                            });
                                          } catch (e) {
                                            setDialogState(() {
                                              isSubmitting = false;
                                              formError = e.toString();
                                            });
                                          }
                                        },
                                  child: Text(
                                    cooldownSeconds > 0
                                        ? 'Resend OTP in 00:${cooldownSeconds.toString().padLeft(2, '0')}'
                                        : 'Resend OTP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: cooldownSeconds > 0 ? AppColors.inkSoft : AppColors.maroon700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        accountType == 'admin' ? 'Create a new Admin Password:' : 'Create a new 4-digit PIN for ${staff?.name ?? "member"}:',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: newPassCtrl,
                        obscureText: true,
                        keyboardType: accountType == 'admin' ? TextInputType.text : TextInputType.number,
                        maxLength: accountType == 'admin' ? 32 : 6,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: accountType == 'admin' ? 'New Admin Password *' : 'New 4-digit PIN *',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          counterText: '',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cooldownTimer?.cancel();
                  Navigator.of(dialogCtx).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        if (step == 1) {
                          if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                            setDialogState(() => formError = 'Please enter a valid email address.');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            formError = null;
                          });
                          try {
                            final res = await ref.read(authServiceProvider).forgotPasswordSendOtp(
                                  email: email,
                                  accountType: accountType,
                                  staffId: staff?.id,
                                );
                            startCooldownTimer(res['cooldown_seconds'] ?? 30, setDialogState);
                            setDialogState(() {
                              isSubmitting = false;
                              step = 2;
                            });
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              formError = e.toString();
                            });
                          }
                        } else if (step == 2) {
                          final otp = otpCtrl.text.trim();
                          if (otp.length != 6) {
                            setDialogState(() => formError = 'Please enter the 6-digit OTP code.');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            formError = null;
                          });
                          try {
                            final res = await ref.read(authServiceProvider).forgotPasswordVerifyOtp(
                                  email: email,
                                  otp: otp,
                                );
                            if (res['verified'] == true) {
                              setDialogState(() {
                                isSubmitting = false;
                                step = 3;
                              });
                            } else {
                              otpCtrl.clear();
                              setDialogState(() {
                                isSubmitting = false;
                                formError = res['message'] ?? 'Invalid verification code';
                              });
                            }
                          } catch (e) {
                            otpCtrl.clear();
                            setDialogState(() {
                              isSubmitting = false;
                              formError = e.toString();
                            });
                          }
                        } else {
                          final newPass = newPassCtrl.text.trim();
                          if (newPass.isEmpty) {
                            setDialogState(() => formError = accountType == 'admin' ? 'Please enter a new password' : 'Please enter a new PIN');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            formError = null;
                          });
                          try {
                            final res = await ref.read(authServiceProvider).forgotPasswordReset(
                                  email: email,
                                  accountType: accountType,
                                  otp: otpCtrl.text.trim(),
                                  newPasswordOrPin: newPass,
                                  staffId: staff?.id,
                                );
                            cooldownTimer?.cancel();
                            if (!mounted) return;
                            Navigator.of(dialogCtx).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Password/PIN reset successfully!'),
                                backgroundColor: AppColors.income,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              formError = e.toString();
                            });
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(step == 1 ? 'Send Reset OTP' : step == 2 ? 'Verify OTP' : 'Reset Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Self Registration Modal for New Billing Members ──────────────────────────
  Future<void> _showRegisterMemberDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '1234');
    final otpCtrl = TextEditingController();

    int step = 1; // 1 = Member Info, 2 = Verify Email OTP
    String? formError;
    bool isSubmitting = false;
    int cooldownSeconds = 0;
    Timer? cooldownTimer;
    String? otpPreview; // Set when email delivery fails — shows OTP directly on screen

    void startCooldownTimer(int seconds, Function setDialogState) {
      cooldownTimer?.cancel();
      setDialogState(() => cooldownSeconds = seconds);
      cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (cooldownSeconds <= 1) {
          t.cancel();
          setDialogState(() => cooldownSeconds = 0);
        } else {
          setDialogState(() => cooldownSeconds--);
        }
      });
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.person_add_alt_1, color: AppColors.maroon700),
                const SizedBox(width: 8),
                Text(
                  step == 1 ? 'Register as Billing Member' : 'Verify Email Address',
                  style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.expenseBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(formError!, style: const TextStyle(color: AppColors.expense, fontSize: 12.5)),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (step == 1) ...[
                      const Text(
                        'Fill in your details to register. Email is mandatory for OTP verification.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Registered Email Address *',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '4-digit Login PIN (Default: 1234) *',
                          prefixIcon: Icon(Icons.lock_outline, size: 20),
                          counterText: '',
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            const Text('We sent a 6-digit verification code to:', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                            const SizedBox(height: 4),
                            Text(
                              emailCtrl.text.trim(),
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.maroon700),
                            ),
                            const SizedBox(height: 12),
                            // Show OTP directly on screen if email delivery failed
                            if (otpPreview != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'Email not received — use this code:',
                                          style: TextStyle(fontSize: 11.5, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      otpPreview!,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 10,
                                        color: Color(0xFF5D4037),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Enter this code in the box below',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF795548)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: otpCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                              decoration: InputDecoration(
                                hintText: '• • • • • •',
                                hintStyle: const TextStyle(letterSpacing: 8, color: AppColors.inkSoft),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      step = 1;
                                      formError = null;
                                    });
                                  },
                                  child: const Text('Edit Details', style: TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                                ),
                                TextButton(
                                  onPressed: (cooldownSeconds > 0 || isSubmitting)
                                      ? null
                                      : () async {
                                          setDialogState(() {
                                            isSubmitting = true;
                                            formError = null;
                                          });
                                          try {
                                            final res = await ref.read(authServiceProvider).sendOtp(
                                                  email: emailCtrl.text.trim(),
                                                  name: nameCtrl.text.trim(),
                                                  phone: phoneCtrl.text.trim(),
                                                  pin: pinCtrl.text.trim(),
                                                );
                                            startCooldownTimer(res['cooldown_seconds'] ?? 30, setDialogState);
                                            setDialogState(() => isSubmitting = false);
                                          } catch (e) {
                                            setDialogState(() {
                                              isSubmitting = false;
                                              formError = e.toString();
                                            });
                                          }
                                        },
                                  child: Text(
                                    cooldownSeconds > 0
                                        ? 'Resend in 00:${cooldownSeconds.toString().padLeft(2, '0')}'
                                        : 'Resend OTP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: cooldownSeconds > 0 ? AppColors.inkSoft : AppColors.maroon700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cooldownTimer?.cancel();
                  Navigator.of(dialogCtx).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final pin = pinCtrl.text.trim();

                        if (step == 1) {
                          if (name.isEmpty) {
                            setDialogState(() => formError = 'Full name is required.');
                            return;
                          }
                          if (phone.isEmpty) {
                            setDialogState(() => formError = 'Mobile phone number is required.');
                            return;
                          }
                          if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                            setDialogState(() => formError = 'Please enter a valid email address.');
                            return;
                          }
                          if (pin.isEmpty) {
                            setDialogState(() => formError = 'Please enter a 4-digit PIN.');
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            formError = null;
                          });

                          try {
                            final res = await ref.read(authServiceProvider).sendOtp(
                                  email: email,
                                  name: name,
                                  phone: phone,
                                  pin: pin,
                                );
                            startCooldownTimer(res['cooldown_seconds'] ?? 30, setDialogState);
                            setDialogState(() {
                              isSubmitting = false;
                              step = 2;
                              // If email delivery failed, server returns the OTP directly
                              otpPreview = res['otp_preview'] as String?;
                            });
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              formError = e.toString();
                            });
                          }
                        } else {
                          final otp = otpCtrl.text.trim();
                          if (otp.length != 6) {
                            setDialogState(() => formError = 'Please enter the 6-digit verification OTP code.');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            formError = null;
                          });

                          try {
                            final res = await ref.read(authServiceProvider).verifyOtp(
                                  email: email,
                                  otp: otp,
                                );

                            if (res['verified'] == true) {
                              cooldownTimer?.cancel();
                              ref.invalidate(staffListProvider);
                              ref.invalidate(pendingStaffListProvider);

                              if (!mounted) return;
                              Navigator.of(dialogCtx).pop();

                              showDialog(
                                context: context,
                                builder: (infoCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: AppColors.income),
                                      SizedBox(width: 8),
                                      Text('Registration Submitted!'),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Welcome $name! Your email has been verified.', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold100.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.line),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.admin_panel_settings_outlined, color: AppColors.maroon700, size: 22),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Awaiting Admin Approval: Please ask the Administrator to approve your account inside Admin Settings to log in.',
                                                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(onPressed: () => Navigator.of(infoCtx).pop(), child: const Text('OK')),
                                  ],
                                ),
                              );
                            } else {
                              otpCtrl.clear();
                              setDialogState(() {
                                isSubmitting = false;
                                formError = res['message'] ?? 'Invalid verification code';
                              });
                            }
                          } catch (e) {
                            otpCtrl.clear();
                            setDialogState(() {
                              isSubmitting = false;
                              formError = e.toString();
                            });
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(step == 1 ? 'Send Verification OTP' : 'Submit & Register'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Admin Login Handler ──────────────────────────────────────────────────
  Future<void> _handleAdminLogin() async {
    final username = _adminUserCtrl.text.trim();
    final password = _adminPassCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _adminError = 'Username and password are required');
      return;
    }

    setState(() {
      _isAdminLoading = true;
      _adminError = null;
    });

    try {
      final res = await ref.read(authServiceProvider).adminLogin(username, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', res['access_token'] ?? '');
      await prefs.setString('user_role', 'admin');

      final staffList = await ref.read(staffListProvider.future);
      final activeStaff = staffList.where((s) => s.isActive && s.isApproved).toList();
      final defaultStaffId = activeStaff.isNotEmpty ? activeStaff.first.id : null;

      if (defaultStaffId != null) {
        await prefs.setString(AppConstants.kCurrentStaffId, defaultStaffId);
        ref.read(currentStaffIdProvider.notifier).state = defaultStaffId;
      }
      ref.read(userRoleProvider.notifier).state = 'admin';

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      setState(() {
        _isAdminLoading = false;
        _adminError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        children: [
          TempleHeader(
            currentTab: 0,
            onStaffTap: null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.line),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Billing Member Login', style: TextStyle(fontWeight: FontWeight.bold))),
                                selected: _selectedTab == 0,
                                selectedColor: AppColors.maroon700,
                                labelStyle: TextStyle(color: _selectedTab == 0 ? Colors.white : AppColors.ink),
                                onSelected: (_) => setState(() => _selectedTab = 0),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Admin Login', style: TextStyle(fontWeight: FontWeight.bold))),
                                selected: _selectedTab == 1,
                                selectedColor: AppColors.maroon700,
                                labelStyle: TextStyle(color: _selectedTab == 1 ? Colors.white : AppColors.ink),
                                onSelected: (_) => setState(() => _selectedTab = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_selectedTab == 0) ...[
                        const Text(
                          "Who's billing today?",
                          style: TextStyle(fontFamily: 'Fraunces', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Select your name & enter PIN to continue',
                          style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
                        ),
                        const SizedBox(height: 16),
                        staffAsync.when(
                          data: (staffList) {
                            final activeStaff = staffList.where((s) => s.isActive && s.isApproved).toList();
                            if (activeStaff.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'No billing members configured yet.\nPlease log in as Admin to add billing members.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                                ),
                              );
                            }
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.25,
                              ),
                              itemCount: activeStaff.length,
                              itemBuilder: (context, index) {
                                final staff = activeStaff[index];
                                return InkWell(
                                  onTap: () => _onStaffCardTap(staff),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.paper,
                                      border: Border.all(color: AppColors.line, width: 1.5),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.maroon700,
                                          child: Text(
                                            staff.initial,
                                            style: const TextStyle(color: AppColors.gold100, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Fraunces'),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          staff.name,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text('🔒 PIN Protected', style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (err, _) => Column(
                            children: [
                              Text('Unable to load staff: $err', style: const TextStyle(color: AppColors.expense)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: () => ref.refresh(staffListProvider), child: const Text('Retry Connection')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: _showRegisterMemberDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.maroon700,
                            side: const BorderSide(color: AppColors.maroon700, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text(
                            'Register as New Billing Member',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                      ] else ...[
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.line)),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Admin Portal',
                                  style: TextStyle(fontFamily: 'Fraunces', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.maroon800),
                                ),
                                const SizedBox(height: 4),
                                const Text('Enter administrator credentials to log in:', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                                const SizedBox(height: 16),
                                if (_adminError != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.expenseBg, borderRadius: BorderRadius.circular(8)),
                                    child: Text(_adminError!, style: const TextStyle(color: AppColors.expense, fontSize: 12.5)),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                TextField(
                                  controller: _adminUserCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline, size: 20),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _adminPassCtrl,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password (Default: kovil2024)',
                                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _showForgotDialog(accountType: 'admin'),
                                    child: const Text('Forgot Admin Password? Reset via Email OTP', style: TextStyle(fontSize: 12, color: AppColors.maroon700)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _isAdminLoading ? null : _handleAdminLogin,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.maroon700, padding: const EdgeInsets.symmetric(vertical: 14)),
                                  child: _isAdminLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Login as Administrator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showServerUrlDialog() async {
    final currentUrl = await OfflineStorageService.getCustomServerUrl();
    final urlCtrl = TextEditingController(text: currentUrl);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi, color: AppColors.maroon700),
            SizedBox(width: 8),
            Text('Configure Backend Server IP', style: TextStyle(fontFamily: 'Fraunces', fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If running the server on a local computer on the temple Wi-Fi network, enter your PC\'s local IP address below:\nExample: http://192.168.1.100:8000',
              style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Backend Server URL',
                prefixIcon: Icon(Icons.link, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlCtrl.text.trim();
              if (newUrl.isNotEmpty) {
                await OfflineStorageService.setCustomServerUrl(newUrl);
                ref.refresh(staffListProvider);
              }
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server URL updated to $newUrl'), backgroundColor: AppColors.income),
              );
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }
}
