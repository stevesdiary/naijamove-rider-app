import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_providers.dart';

/// Session flags that drive first-run vs returning behaviour.
class Session {
  const Session({
    this.onboarded = false,
    this.loggedIn = false,
    this.hasTrips = true,
    this.pendingRating = true,
    this.walletBalance = Mock.walletBalance,
    this.offline = false,
    this.themeMode = ThemeMode.system,
  });
  final bool onboarded;
  final bool loggedIn;
  final bool hasTrips;
  final bool pendingRating;
  final int walletBalance;
  final bool offline;
  final ThemeMode themeMode;

  Session copyWith({
    bool? onboarded,
    bool? loggedIn,
    bool? hasTrips,
    bool? pendingRating,
    int? walletBalance,
    bool? offline,
    ThemeMode? themeMode,
  }) => Session(
    onboarded: onboarded ?? this.onboarded,
    loggedIn: loggedIn ?? this.loggedIn,
    hasTrips: hasTrips ?? this.hasTrips,
    pendingRating: pendingRating ?? this.pendingRating,
    walletBalance: walletBalance ?? this.walletBalance,
    offline: offline ?? this.offline,
    themeMode: themeMode ?? this.themeMode,
  );
}

class SessionController extends Notifier<Session> {
  @override
  Session build() => const Session();

  void completeOnboarding() => state = state.copyWith(onboarded: true);

  /// Called after OTP verify — persists tokens then marks session live.
  Future<void> loginWithTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await ref.read(tokenStoreProvider).save(
      access: accessToken,
      refresh: refreshToken,
      userId: userId,
    );
    state = state.copyWith(loggedIn: true, onboarded: true);
  }

  /// Mock-only shortcut used by prototype flows.
  void login() => state = state.copyWith(loggedIn: true, onboarded: true);

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const Session(onboarded: true);
  }

  void dismissPendingRating() => state = state.copyWith(pendingRating: false);
  void topUp(int amount) =>
      state = state.copyWith(walletBalance: state.walletBalance + amount);
  void toggleOffline() => state = state.copyWith(offline: !state.offline);
  void setTheme(ThemeMode m) => state = state.copyWith(themeMode: m);
}

final sessionProvider = NotifierProvider<SessionController, Session>(
  SessionController.new,
);

/// Draft of the ride being requested (destination search → confirm).
class RideDraft {
  const RideDraft({
    this.pickup = Mock.pickup,
    this.destination,
    this.stops = const [],
    this.category = VehicleCategory.economy,
    this.payment = Mock.visa,
    this.mode = TripMode.immediate,
    this.promo,
  });
  final Place pickup;
  final Place? destination;
  final List<Place> stops;
  final VehicleCategory category;
  final PaymentMethod payment;
  final TripMode mode;
  final String? promo;

  FareQuote get quote => Mock.quotes.firstWhere((q) => q.category == category);

  RideDraft copyWith({
    Place? pickup,
    Place? destination,
    List<Place>? stops,
    VehicleCategory? category,
    PaymentMethod? payment,
    TripMode? mode,
    String? promo,
  }) => RideDraft(
    pickup: pickup ?? this.pickup,
    destination: destination ?? this.destination,
    stops: stops ?? this.stops,
    category: category ?? this.category,
    payment: payment ?? this.payment,
    mode: mode ?? this.mode,
    promo: promo ?? this.promo,
  );
}

class RideDraftController extends Notifier<RideDraft> {
  @override
  RideDraft build() => const RideDraft();
  void setDestination(Place p) => state = state.copyWith(destination: p);
  void setPickup(Place p) => state = state.copyWith(pickup: p);
  void addStop(Place p) {
    if (state.stops.length >= 3) return;
    state = state.copyWith(stops: [...state.stops, p]);
  }

  void setCategory(VehicleCategory c) => state = state.copyWith(category: c);
  void setPayment(PaymentMethod p) => state = state.copyWith(payment: p);
  void setMode(TripMode m) => state = state.copyWith(mode: m);
  void reset() => state = const RideDraft();
}

final rideDraftProvider = NotifierProvider<RideDraftController, RideDraft>(
  RideDraftController.new,
);

/// Simulated live-trip state machine so the prototype flows end-to-end.
class ActiveTrip {
  const ActiveTrip({
    required this.status,
    this.driver,
    this.etaMin = 4,
    this.progress = 0,
    this.noDrivers = false,
    this.pinRevealed = false,
    this.driverCancelled = false,
  });
  final TripStatus status;
  final Driver? driver;
  final int etaMin;
  final double progress;
  final bool noDrivers;
  final bool pinRevealed;
  final bool driverCancelled;

  ActiveTrip copyWith({
    TripStatus? status,
    Driver? driver,
    int? etaMin,
    double? progress,
    bool? noDrivers,
    bool? pinRevealed,
    bool? driverCancelled,
  }) => ActiveTrip(
    status: status ?? this.status,
    driver: driver ?? this.driver,
    etaMin: etaMin ?? this.etaMin,
    progress: progress ?? this.progress,
    noDrivers: noDrivers ?? this.noDrivers,
    pinRevealed: pinRevealed ?? this.pinRevealed,
    driverCancelled: driverCancelled ?? this.driverCancelled,
  );
}

class ActiveTripController extends Notifier<ActiveTrip> {
  Timer? _timer;
  Timer? _pinTimer;

  @override
  ActiveTrip build() {
    ref.onDispose(() {
      _timer?.cancel();
      _pinTimer?.cancel();
    });
    return const ActiveTrip(status: TripStatus.requested);
  }

  /// Start searching. After ~3s a driver is matched (or, if [simulateNoDrivers], times out).
  void startSearch({bool simulateNoDrivers = false}) {
    _timer?.cancel();
    state = const ActiveTrip(status: TripStatus.requested);
    _timer = Timer(const Duration(seconds: 3), () {
      if (simulateNoDrivers) {
        state = state.copyWith(noDrivers: true);
      } else {
        state = ActiveTrip(
          status: TripStatus.matched,
          driver: Mock.driver,
          etaMin: 4,
        );
      }
    });
  }

  void cancelSearch() {
    _timer?.cancel();
    state = const ActiveTrip(status: TripStatus.requested);
  }

  void driverArriving() =>
      state = state.copyWith(status: TripStatus.driverArriving, etaMin: 2);
  void driverArrived() =>
      state = state.copyWith(status: TripStatus.driverArrived, etaMin: 0);
  void startTrip() {
    state = state.copyWith(status: TripStatus.inProgress, progress: 0.05);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      final next = (state.progress + 0.06).clamp(0.0, 1.0);
      state = state.copyWith(progress: next, etaMin: ((1 - next) * 40).round());
      if (next >= 1) _timer?.cancel();
    });
  }

  void complete() {
    _timer?.cancel();
    state = state.copyWith(status: TripStatus.completed, progress: 1);
  }

  void driverCancels() {
    _timer?.cancel();
    state = state.copyWith(driverCancelled: true, status: TripStatus.cancelled);
  }

  void revealPin() {
    state = state.copyWith(pinRevealed: true);
    _pinTimer?.cancel();
    _pinTimer = Timer(const Duration(seconds: 10), () {
      if (state.pinRevealed) state = state.copyWith(pinRevealed: false);
    });
  }

  void reset() {
    _timer?.cancel();
    _pinTimer?.cancel();
    state = const ActiveTrip(status: TripStatus.requested);
  }
}

final activeTripProvider = NotifierProvider<ActiveTripController, ActiveTrip>(
  ActiveTripController.new,
);

/// Rating flow scratch state (10.1 → 10.2 → 10.3).
class RatingDraft {
  const RatingDraft({
    this.stars = 0,
    this.tags = const {},
    this.comment = '',
    this.tip,
  });
  final int stars;
  final Set<String> tags;
  final String comment;
  final int? tip;
  RatingDraft copyWith({
    int? stars,
    Set<String>? tags,
    String? comment,
    int? tip,
    bool clearTip = false,
  }) => RatingDraft(
    stars: stars ?? this.stars,
    tags: tags ?? this.tags,
    comment: comment ?? this.comment,
    tip: clearTip ? null : (tip ?? this.tip),
  );
}

class RatingController extends Notifier<RatingDraft> {
  @override
  RatingDraft build() => const RatingDraft();
  void setStars(int s) => state = state.copyWith(stars: s, tags: {});
  void toggleTag(String t) {
    final tags = {...state.tags};
    tags.contains(t) ? tags.remove(t) : tags.add(t);
    state = state.copyWith(tags: tags);
  }

  void setComment(String c) => state = state.copyWith(comment: c);
  void setTip(int? t) => state = state.copyWith(tip: t, clearTip: t == null);
  void reset() => state = const RatingDraft();
}

final ratingProvider = NotifierProvider<RatingController, RatingDraft>(
  RatingController.new,
);

/// Support case being drafted (11.2 → 11.3 → 11.4).
class CaseDraft {
  const CaseDraft({
    this.category,
    this.trip,
    this.description = '',
    this.resolution,
  });
  final String? category;
  final Trip? trip;
  final String description;
  final String? resolution;
  CaseDraft copyWith({
    String? category,
    Trip? trip,
    String? description,
    String? resolution,
  }) => CaseDraft(
    category: category ?? this.category,
    trip: trip ?? this.trip,
    description: description ?? this.description,
    resolution: resolution ?? this.resolution,
  );
}

class CaseDraftController extends Notifier<CaseDraft> {
  @override
  CaseDraft build() => const CaseDraft();
  void setCategory(String c) => state = state.copyWith(category: c);
  void setTrip(Trip? t) => state = CaseDraft(
    category: state.category,
    trip: t,
    description: state.description,
    resolution: state.resolution,
  );
  void setResolution(String r) => state = state.copyWith(resolution: r);
  void reset() => state = const CaseDraft();
}

final caseDraftProvider = NotifierProvider<CaseDraftController, CaseDraft>(
  CaseDraftController.new,
);
