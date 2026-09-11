import 'package:flutter_test/flutter_test.dart';
import 'package:qmmc_pd1_mobile/app/qmmc_app.dart';

void main() {
  testWidgets('shows the login screen on startup', (tester) async {
    await tester.pumpWidget(const QmmcApp());

    expect(find.text('QMMC PD1'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
