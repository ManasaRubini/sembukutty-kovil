import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/screens/staff_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.load();
  runApp(const ProviderScope(child: SembukuttyApp()));
}

class SembukuttyApp extends StatelessWidget {
  const SembukuttyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sembukutty Sastha Kovil',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const StaffSelectionScreen(),
    );
  }
}
