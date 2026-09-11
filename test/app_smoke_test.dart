import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijamove_rider/app/app.dart';

void main() {
  testWidgets('splash → onboarding → phone entry → OTP', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: NaijaMoveApp()));
    expect(find.text('Built for how Nigeria moves'), findsOneWidget);

    // Splash auto-advances after 2s to onboarding on first install.
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Rides that work for Lagos'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your phone number'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '8031234567');
    await tester.pumpAndSettle();
    // Returning-user copy appears for the registered sample number.
    expect(find.textContaining('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Send Verification Code'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Enter the code'), findsOneWidget);
  });
}
