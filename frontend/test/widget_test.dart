import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembukutty_kovil/main.dart';
import 'package:sembukutty_kovil/providers/providers.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staffListProvider.overrideWith((ref) async => []),
          pendingStaffListProvider.overrideWith((ref) async => []),
          setupStatusProvider.overrideWith((ref) async => {
                'admin_registered': true,
                'total_staff': 0,
                'pending_approvals': 0,
              }),
        ],
        child: const SembukuttyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SembukuttyApp), findsOneWidget);
  });
}
