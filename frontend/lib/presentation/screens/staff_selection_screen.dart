import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/temple_header.dart';
import 'main_shell.dart';

class StaffSelectionScreen extends ConsumerStatefulWidget {
  const StaffSelectionScreen({super.key});

  @override
  ConsumerState<StaffSelectionScreen> createState() => _StaffSelectionScreenState();
}

class _StaffSelectionScreenState extends ConsumerState<StaffSelectionScreen> {
  int _selectedTab = 0; // 0 = Billing Member Login, 1 = Admin Login

  // Member login controllers
  final _memberIdCtrl = TextEditingController();
  final _memberPinCtrl = TextEditingController();
  bool _isMemberLoading = false;
  String? _memberError;

  // Admin login controllers
  final _adminUserCtrl = TextEditingController(text: 'admin');
  final _adminPassCtrl = TextEditingController(text: 'kovil2024');
  bool _isAdminLoading = false;
  String? _adminError;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  /// Auto-login persistence: If user is already logged in, enter app directly
  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.kIsLoggedIn) ?? false;
    final staffId = prefs.getString(AppConstants.kCurrentStaffId);
    final userRole = prefs.getString(AppConstants.kUserRole) ?? 'staff';

    if (isLoggedIn && staffId != null && staffId.isNotEmpty && mounted) {
      ref.read(currentStaffIdProvider.notifier).state = staffId;
      ref.read(userRoleProvider.notifier).state = userRole;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  void dispose() {
    _memberIdCtrl.dispose();
    _memberPinCtrl.dispose();
    _adminUserCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  // ─── Member Login Handler ──────────────────────────────────────────────────
  Future<void> _handleMemberLogin() async {
    final identifier = _memberIdCtrl.text.trim();
    final pin = _memberPinCtrl.text.trim();

    if (identifier.isEmpty || pin.isEmpty) {
      setState(() => _memberError = 'Username / Phone / Email and PIN are required');
      return;
    }

    setState(() {
      _isMemberLoading = true;
      _memberError = null;
    });

    try {
      final res = await ref.read(authServiceProvider).staffLogin(identifier, pin);
      final staffId = res['staff_id'] as String? ?? identifier;
      final token = res['access_token'] as String? ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.kIsLoggedIn, true);
      await prefs.setString(AppConstants.kCurrentStaffId, staffId);
      await prefs.setString(AppConstants.kUserRole, 'staff');
      await prefs.setString('auth_token', token);

      ref.read(currentStaffIdProvider.notifier).state = staffId;
      ref.read(userRoleProvider.notifier).state = 'staff';

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      setState(() {
        _isMemberLoading = false;
        _memberError = e.toString();
      });
    }
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
      await prefs.setBool(AppConstants.kIsLoggedIn, true);
      await prefs.setString(AppConstants.kUserRole, 'admin');
      await prefs.setString('auth_token', res['access_token'] ?? '');

      final staffList = await ref.read(staffListProvider.future);
      final activeStaff = staffList.where((s) => s.isActive && s.isApproved).toList();
      final defaultStaffId = activeStaff.isNotEmpty ? activeStaff.first.id : 'admin';

      await prefs.setString(AppConstants.kCurrentStaffId, defaultStaffId);
      ref.read(currentStaffIdProvider.notifier).state = defaultStaffId;
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

  // ─── Forgot Password / PIN via Email OTP Modal ──────────────────────────────
  Future<void> _showForgotDialog({String accountType = 'member'}) async {
    final emailCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    int step = 1;
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
                      const Text(
                        'Enter your registered email address to receive a 6-digit OTP code.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Registered Email Address',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                    ] else if (step == 2) ...[
                      Center(
                        child: Column(
                          children: [
                            const Text('Enter the 6-digit code sent to:', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                            const SizedBox(height: 4),
                            Text(
                              emailCtrl.text.trim(),
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.maroon700),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: otpCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                              decoration: InputDecoration(
                                hintText: '• • • • • •',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 10),
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
                                cooldownSeconds > 0 ? 'Resend in 00:${cooldownSeconds.toString().padLeft(2, '0')}' : 'Resend OTP',
                                style: const TextStyle(color: AppColors.maroon700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        accountType == 'admin' ? 'Set your new Admin Password:' : 'Set your new 4-digit PIN:',
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: newPassCtrl,
                        obscureText: true,
                        maxLength: accountType == 'admin' ? 32 : 6,
                        decoration: InputDecoration(
                          labelText: accountType == 'admin' ? 'New Password' : 'New 4-digit PIN',
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
                          if (email.isEmpty || !email.contains('@')) {
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
                              setDialogState(() {
                                isSubmitting = false;
                                formError = res['message'] ?? 'Invalid OTP code.';
                              });
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              formError = e.toString();
                            });
                          }
                        } else {
                          final newValue = newPassCtrl.text.trim();
                          if (newValue.isEmpty) {
                            setDialogState(() => formError = 'Please enter your new value.');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            formError = null;
                          });
                          try {
                            await ref.read(authServiceProvider).verifyResetRequest(
                                  accountType: accountType,
                                  identifier: email,
                                );
                            cooldownTimer?.cancel();
                            if (!mounted) return;
                            Navigator.of(dialogCtx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password/PIN reset successfully! You can now log in.')),
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
                    : Text(step == 1 ? 'Send OTP' : step == 2 ? 'Verify OTP' : 'Reset Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Self Registration Modal ────────────────────────────────────────────────
  Future<void> _showRegisterMemberDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '1234');
    final otpCtrl = TextEditingController();

    int step = 1;
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
                            const SizedBox(height: 8),
                            const Text(
                              'Please check your inbox and spam folder.',
                              style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
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
                                            Icon(Icons.hourglass_empty, color: AppColors.maroon700, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Your registration request is pending Admin approval. Please ask the Admin to approve your account inside Admin Settings.',
                                                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(infoCtx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                formError = res['message'] ?? 'Invalid verification OTP code.';
                              });
                            }
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
                    : Text(step == 1 ? 'Send Verification OTP' : 'Submit & Register'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  constraints: const BoxConstraints(maxWidth: 440),
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
                      // Tab Bar Selector
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
                                onSelected: (_) => setState(() {
                                  _selectedTab = 0;
                                  _memberError = null;
                                }),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Admin Login', style: TextStyle(fontWeight: FontWeight.bold))),
                                selected: _selectedTab == 1,
                                selectedColor: AppColors.maroon700,
                                labelStyle: TextStyle(color: _selectedTab == 1 ? Colors.white : AppColors.ink),
                                onSelected: (_) => setState(() {
                                  _selectedTab = 1;
                                  _adminError = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── BILLING MEMBER LOGIN FORM ───────────────────────────────
                      if (_selectedTab == 0) ...[
                        const Text(
                          'Billing Member Sign In',
                          style: TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Type your Username, Mobile, or Email & PIN to sign in',
                          style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        if (_memberError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.expenseBg, borderRadius: BorderRadius.circular(8)),
                            child: Text(_memberError!, style: const TextStyle(color: AppColors.expense, fontSize: 12.5)),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextField(
                          controller: _memberIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Username / Phone / Email',
                            hintText: 'Enter your name, mobile number or email',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _memberPinCtrl,
                          obscureText: true,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '4-digit Login PIN / Password',
                            hintText: '••••',
                            prefixIcon: Icon(Icons.lock_outline, size: 20),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotDialog(accountType: 'member'),
                            child: const Text('Forgot PIN?', style: TextStyle(color: AppColors.maroon700, fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isMemberLoading ? null : _handleMemberLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.maroon700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isMemberLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Sign In to Billing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _showRegisterMemberDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.maroon700,
                            side: const BorderSide(color: AppColors.maroon700, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text(
                            'Register as New Billing Member',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ] else ...[
                        // ─── ADMIN LOGIN FORM ──────────────────────────────────────
                        const Text(
                          'Admin Sign In',
                          style: TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter Administrator credentials to manage Kovil accounts',
                          style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        if (_adminError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.expenseBg, borderRadius: BorderRadius.circular(8)),
                            child: Text(_adminError!, style: const TextStyle(color: AppColors.expense, fontSize: 12.5)),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextField(
                          controller: _adminUserCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Admin Username',
                            prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _adminPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Admin Password',
                            prefixIcon: Icon(Icons.lock_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotDialog(accountType: 'admin'),
                            child: const Text('Forgot Password?', style: TextStyle(color: AppColors.maroon700, fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isAdminLoading ? null : _handleAdminLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.maroon700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isAdminLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Login as Administrator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
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
}
