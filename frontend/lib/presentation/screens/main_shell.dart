import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../widgets/temple_header.dart';
import 'dashboard/dashboard_screen.dart';
import 'entries/my_entries_screen.dart';
import 'reports/reports_screen.dart';
import 'documents/documents_screen.dart';
import 'settings/settings_screen.dart';
import 'staff_selection_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentTab = 0;

  Future<void> _switchStaff() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.maroon700),
            SizedBox(width: 8),
            Text('Confirm Logout', style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your billing session?',
          style: TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.inkSoft)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.maroon700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.kIsLoggedIn, false);
    await prefs.remove(AppConstants.kCurrentStaffId);
    await prefs.remove(AppConstants.kUserRole);
    await prefs.remove('auth_token');

    ref.read(currentStaffIdProvider.notifier).state = null;

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StaffSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffId = ref.watch(currentStaffIdProvider);
    final role = ref.watch(userRoleProvider);
    final staffListAsync = ref.watch(staffListProvider);

    String? staffName;
    if (role == 'admin') {
      staffName = 'Admin';
    } else {
      staffListAsync.whenData((list) {
        final found = list.where((s) => s.id == staffId);
        if (found.isNotEmpty) {
          staffName = found.first.name;
        }
      });
    }

    final screens = [
      DashboardScreen(onNavigateTab: (tab) => setState(() => _currentTab = tab)),
      const MyEntriesScreen(),
      const ReportsScreen(),
      const DocumentsScreen(),
      SettingsScreen(
        onSwitchStaff: _switchStaff,
        onNavigateTab: (tab) => setState(() => _currentTab = tab),
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentTab != 0) {
          // If on Entries/Reports/Receipts/Settings tab, press Back returns to Dashboard tab
          setState(() => _currentTab = 0);
        } else {
          // If already on Dashboard, press Back minimizes app to phone Home Screen (like Instagram)
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            TempleHeader(
              isAdmin: role == 'admin',
              staffName: staffName,
              currentTab: _currentTab,
              onTabSelected: (tab) => setState(() => _currentTab = tab),
              onStaffTap: _switchStaff,
            ),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: MediaQuery.of(context).size.width < 600
            ? BottomNavigationBar(
                currentIndex: _currentTab,
                onTap: (tab) => setState(() => _currentTab = tab),
                selectedItemColor: AppColors.maroon700,
                unselectedItemColor: AppColors.inkSoft,
                type: BottomNavigationBarType.fixed,
                items: [
                  const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                  BottomNavigationBarItem(icon: const Icon(Icons.list_alt_outlined), activeIcon: const Icon(Icons.list_alt), label: role == 'admin' ? 'All Entries' : 'Entries'),
                  const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Reports'),
                  BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Receipts'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
                ],
              )
            : null,
      ),
    );
  }
}
