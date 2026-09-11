import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../features/home/destination_search_screen.dart';
import '../features/home/home_map_screen.dart';
import '../features/onboarding/auth_screens.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/profile/profile_screens.dart';
import '../features/rating/rating_screens.dart';
import '../features/ride/confirm_ride_screen.dart';
import '../features/ride/ride_options_screen.dart';
import '../features/ride/schedule_negotiate_screens.dart';
import '../features/support/support_screens.dart';
import '../features/trip/active_trip_screens.dart';
import '../features/trips/trips_screens.dart';
import '../features/wallet/wallet_screens.dart';
import 'routes.dart';
import 'shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// `--dart-define=START_ROUTE=/home` jumps straight to a screen (demos, screenshots).
const startRoute = String.fromEnvironment(
  'START_ROUTE',
  defaultValue: Routes.splash,
);

/// Slide-up transition for overlay-style screens (search, chats).
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: startRoute,
  routes: [
    // Flow 1
    GoRoute(
      path: Routes.splash,
      pageBuilder: (_, s) => _fade(s, const SplashScreen()),
    ),
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: (_, s) => _fade(s, const OnboardingScreen()),
    ),
    GoRoute(
      path: Routes.phone,
      pageBuilder: (_, s) => _fade(s, const PhoneEntryScreen()),
    ),
    GoRoute(
      path: Routes.otp,
      builder: (_, s) {
        final extra = s.extra;
        if (extra is ({bool returning, String phone})) {
          return OtpScreen(returningUser: extra.returning, phone: extra.phone);
        }
        return OtpScreen(returningUser: extra == true);
      },
    ),
    GoRoute(
      path: Routes.profileSetup,
      builder: (_, _) => const ProfileSetupScreen(),
    ),

    // Shell with 4 tabs
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, _) => const HomeMapScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.trips,
              builder: (_, _) => const TripHistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.wallet,
              builder: (_, _) => const WalletScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Flow 2
    GoRoute(
      path: Routes.search,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _slideUp(s, const DestinationSearchScreen()),
    ),
    GoRoute(
      path: Routes.rideOptions,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const RideOptionsScreen(),
    ),
    GoRoute(
      path: Routes.confirmRide,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const ConfirmRideScreen(),
    ),
    GoRoute(
      path: Routes.scheduleRide,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const ScheduleRideScreen(),
    ),
    GoRoute(
      path: Routes.negotiateRide,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const NegotiatedRideScreen(),
    ),

    // Flow 3
    GoRoute(
      path: Routes.searching,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const SearchingScreen()),
    ),
    GoRoute(
      path: Routes.driverMatched,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const DriverMatchedScreen()),
    ),
    GoRoute(
      path: Routes.driverArriving,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const DriverArrivingScreen()),
    ),
    GoRoute(
      path: Routes.driverArrived,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const DriverArrivedScreen()),
    ),
    GoRoute(
      path: Routes.tripInProgress,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const TripInProgressScreen()),
    ),
    GoRoute(
      path: Routes.sos,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const SosScreen()),
    ),
    GoRoute(
      path: Routes.tripCompleted,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const TripCompletedScreen()),
    ),
    GoRoute(
      path: Routes.driverCancelled,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const DriverCancelledScreen()),
    ),
    GoRoute(
      path: Routes.driverChat,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _slideUp(s, const DriverChatScreen()),
    ),

    // Flow 4
    GoRoute(
      path: Routes.topUp,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const TopUpScreen(),
    ),
    GoRoute(
      path: Routes.transactions,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const TransactionsScreen(),
    ),
    GoRoute(
      path: Routes.addCard,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const AddCardScreen(),
    ),

    // Flow 5
    GoRoute(
      path: Routes.receiptPattern,
      parentNavigatorKey: _rootKey,
      builder: (_, s) => TripReceiptScreen(tripId: s.pathParameters['id']!),
    ),

    // Flow 6 / 7 / 9
    GoRoute(
      path: Routes.savedPlaces,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const SavedPlacesScreen(),
    ),
    GoRoute(
      path: Routes.emergencyContacts,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const EmergencyContactsScreen(),
    ),
    GoRoute(
      path: Routes.promotions,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const PromotionsScreen(),
    ),
    GoRoute(
      path: Routes.myRating,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const MyRatingScreen(),
    ),
    GoRoute(
      path: Routes.notifications,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const NotificationsScreen(),
    ),
    GoRoute(
      path: Routes.whatsapp,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _slideUp(s, const WhatsAppHandoffScreen()),
    ),

    // Flow 10
    GoRoute(
      path: Routes.rate,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _slideUp(s, const PostTripRatingScreen()),
    ),
    GoRoute(
      path: Routes.tip,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const TipDriverScreen(),
    ),
    GoRoute(
      path: Routes.ratingDone,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const RatingSubmittedScreen()),
    ),
    GoRoute(
      path: Routes.driverProfilePattern,
      parentNavigatorKey: _rootKey,
      builder: (_, s) => DriverProfileScreen(driverId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: Routes.reportDriver,
      parentNavigatorKey: _rootKey,
      builder: (_, s) =>
          ReportDriverScreen(trip: s.extra is Trip ? s.extra as Trip : null),
    ),

    // Flow 11
    GoRoute(
      path: Routes.support,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const SupportHomeScreen(),
    ),
    GoRoute(
      path: Routes.issueCategory,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const IssueCategoryScreen(),
    ),
    GoRoute(
      path: Routes.issueForm,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const IssueFormScreen(),
    ),
    GoRoute(
      path: Routes.caseSubmitted,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => _fade(s, const CaseSubmittedScreen()),
    ),
    GoRoute(
      path: Routes.myCases,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const MyCasesScreen(),
    ),
    GoRoute(
      path: Routes.caseDetailPattern,
      parentNavigatorKey: _rootKey,
      builder: (_, s) => CaseChatScreen(reference: s.pathParameters['ref']!),
    ),
    GoRoute(
      path: Routes.caseResolved,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const CaseResolvedScreen(),
    ),
    GoRoute(
      path: Routes.faq,
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const FaqArticleScreen(),
    ),
  ],
);
