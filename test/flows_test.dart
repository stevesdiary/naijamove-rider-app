import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijamove_rider/app/app.dart';
import 'package:naijamove_rider/app/router.dart';
import 'package:naijamove_rider/app/routes.dart';
import 'package:naijamove_rider/app/state/app_state.dart';

/// Screens have looping animations (map pulse, loaders), so pumpAndSettle never settles.
extension Settle on WidgetTester {
  Future<void> settle() async {
    await pump();
    await pump(const Duration(milliseconds: 350));
    await pump(const Duration(milliseconds: 350));
  }
}

/// Pumps the app already logged in and lands on [location].
Future<ProviderContainer> pumpAt(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(sessionProvider.notifier).login();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const NaijaMoveApp(),
    ),
  );
  appRouter.go(location);
  await tester.settle();
  return container;
}

void main() {
  testWidgets('book a ride end-to-end', (tester) async {
    final c = await pumpAt(tester, Routes.home);
    expect(find.text('Where to?'), findsOneWidget);

    await tester.tap(find.text('Where to?'));
    await tester.settle();
    await tester.tap(find.text('Ikeja City Mall').first);
    await tester.settle();
    expect(find.text('Choose a ride'), findsOneWidget);

    await tester.tap(find.text('Comfort'));
    await tester.settle();
    expect(find.text('Request Comfort'), findsOneWidget);
    await tester.tap(find.text('Request Comfort'));
    await tester.settle();
    expect(find.text('Confirm Ride'), findsOneWidget);

    await tester.tap(find.text('Confirm Ride'));
    await tester.settle();
    expect(find.text('Finding your driver…'), findsOneWidget);

    // Driver matched after 3s.
    await tester.pump(const Duration(seconds: 3, milliseconds: 200));
    await tester.settle();
    expect(find.text('Driver on the way'), findsOneWidget);
    await tester.tap(find.text('Reveal'));
    await tester.settle();
    expect(find.text('4821'), findsOneWidget);

    await tester.tap(find.text('Driver is arriving'));
    await tester.settle();
    await tester.tap(find.text('Driver has arrived'));
    await tester.settle();
    expect(find.text('LND 482 KJ'), findsWidgets);
    await tester.tap(find.text('Start Trip'));
    await tester.settle();
    expect(find.text('Skip to arrival'), findsOneWidget);

    await tester.tap(find.text('Skip to arrival'));
    await tester.settle();
    expect(find.text('Trip Complete!'), findsOneWidget);

    await tester.tap(find.text('Rate Your Trip'));
    await tester.settle();
    expect(find.textContaining('How was your ride'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3));
    await tester.settle();
    expect(find.text('Good'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.settle();
    expect(find.textContaining('Leave a tip'), findsOneWidget);
    await tester.tap(find.text('₦ 500'));
    await tester.settle();
    await tester.tap(find.text('Send ₦ 500 Tip'));
    await tester.settle();
    expect(find.text('Thanks for your feedback!'), findsOneWidget);
    expect(c.read(ratingProvider).tip, 500);

    // Auto-dismiss returns home; let the PIN auto-hide timer expire too.
    await tester.pump(const Duration(seconds: 11));
    await tester.settle();
    expect(find.text('Where to?'), findsOneWidget);
  });

  testWidgets('driver cancelled and no-drivers states render', (tester) async {
    final c = await pumpAt(tester, Routes.driverCancelled);
    expect(find.text('Your driver cancelled'), findsOneWidget);
    c.read(activeTripProvider.notifier).startSearch(simulateNoDrivers: true);
    appRouter.go(Routes.searching);
    await tester.pump(const Duration(seconds: 3, milliseconds: 200));
    await tester.settle();
    expect(find.text('No drivers nearby right now'), findsOneWidget);
  });

  testWidgets('tabs, wallet and profile screens render', (tester) async {
    await pumpAt(tester, Routes.trips);
    expect(find.text('Your Trips'), findsOneWidget);
    await tester.tap(find.text('Scheduled'));
    await tester.settle();
    await tester.tap(find.text('Wallet'));
    await tester.settle();
    expect(find.text('₦ 2,400'), findsOneWidget);
    await tester.tap(find.text('Top Up'));
    await tester.settle();
    await tester.tap(find.text('Top Up ₦ 1,000'));
    await tester.settle();
    expect(find.text('₦ 3,400'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.settle();
    expect(find.text('Tunde Adeyemi'), findsOneWidget);
  });

  testWidgets('secondary screens render without overflow', (tester) async {
    await pumpAt(tester, Routes.home);
    for (final r in [
      Routes.transactions,
      Routes.addCard,
      Routes.receipt('trp_now'),
      Routes.savedPlaces,
      Routes.emergencyContacts,
      Routes.promotions,
      Routes.myRating,
      Routes.notifications,
      Routes.whatsapp,
      Routes.driverProfile('drv_1'),
      Routes.reportDriver,
      Routes.support,
      Routes.issueCategory,
      Routes.issueForm,
      Routes.caseSubmitted,
      Routes.myCases,
      Routes.caseDetail('NM-2026-00847'),
      Routes.caseResolved,
      Routes.driverChat,
      Routes.faq,
      Routes.scheduleRide,
      Routes.negotiateRide,
      Routes.sos,
      Routes.tripInProgress,
    ]) {
      appRouter.go(r);
      await tester.settle();
      expect(tester.takeException(), isNull, reason: 'exception on $r');
    }
  });

  testWidgets('dark mode renders home and trip screens', (tester) async {
    final c = await pumpAt(tester, Routes.home);
    c.read(sessionProvider.notifier).setTheme(ThemeMode.dark);
    await tester.settle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    appRouter.go(Routes.driverChat);
    await tester.settle();
    expect(tester.takeException(), isNull);
  });
}
