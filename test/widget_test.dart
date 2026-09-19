import 'package:flutter_test/flutter_test.dart';
import 'package:rmc_clinic_health/app.dart';

void main() {
  testWidgets('shows role-based clinic login', (tester) async {
    await tester.pumpWidget(const ClinicApp());
    expect(find.text('Opening your workspace…'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Opening your workspace…'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Clinic Staff'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
  });
}
