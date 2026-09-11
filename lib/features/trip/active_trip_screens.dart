import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/map_canvas.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../ride/ride_options_screen.dart';
import 'trip_widgets.dart';

Offset _pickupAt(RideDraft d) => d.pickup.at ?? Mock.pickup.at!;
Offset _destAt(RideDraft d) =>
    (d.destination ?? Mock.destination).at ?? Mock.destination.at!;

/// 3.1 — Searching for driver (+ no-drivers state after timeout).
class SearchingScreen extends ConsumerWidget {
  const SearchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(activeTripProvider);
    final draft = ref.watch(rideDraftProvider);
    final theme = Theme.of(context);

    // Auto-advance once matched.
    ref.listen(activeTripProvider, (_, next) {
      if (next.status == TripStatus.matched && context.mounted) {
        context.go(Routes.driverMatched);
      }
    });

    return MapSheetScaffold(
      showBack: false,
      mapFraction: 0.6,
      map: MapCanvas(
        pickup: _pickupAt(draft),
        pulse: true,
        drivers: const [
          MapDriver(Offset(0.15, 0.4), heading: 0.9),
          MapDriver(Offset(0.6, 0.35), heading: -2.2),
          MapDriver(Offset(0.5, 0.8), heading: -0.6),
        ],
      ),
      sheet: SheetSurface(
        scrollable: true,
        child: trip.noDrivers
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No drivers nearby right now',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try again in a few minutes or schedule a ride',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Try Again',
                    onPressed: () =>
                        ref.read(activeTripProvider.notifier).startSearch(),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Schedule a Ride',
                    onPressed: () => context.push(Routes.scheduleRide),
                  ),
                  GhostButton(
                    label: 'Cancel',
                    onPressed: () {
                      ref.read(activeTripProvider.notifier).reset();
                      context.go(Routes.home);
                    },
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Finding your driver…',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connecting to verified NaijaMove drivers nearby',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  // Selected ride summary
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.tint,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            draft.category.icon,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.category.label,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                '${draft.category.seats} seats · AC · guaranteed price',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              naira(Mock.fareEstimate),
                              style: AppText.fare(context, size: 20),
                            ),
                            Text(
                              draft.payment.type == PaymentMethodType.cash
                                  ? 'Cash trip'
                                  : 'Cashless trip',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Availability hint
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.tint,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.local_taxi_rounded,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'High driver availability near ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.textPrimary,
                              ),
                              children: [
                                TextSpan(
                                  text: draft.pickup.address.split(',').first,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      '. Drivers typically accept within 45 seconds.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(minHeight: 4),
                  ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: 'Cancel Search',
                    icon: Icons.close_rounded,
                    color: AppColors.dangerRed,
                    onPressed: () {
                      ref.read(activeTripProvider.notifier).cancelSearch();
                      context.go(Routes.home);
                    },
                  ),
                  // Demo helper to preview the timeout state.
                  Center(
                    child: LinkText(
                      'Simulate no drivers',
                      size: 12,
                      color: context.textSecondary,
                      onTap: () => ref
                          .read(activeTripProvider.notifier)
                          .startSearch(simulateNoDrivers: true),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 3.2 — Driver matched.
class DriverMatchedScreen extends ConsumerWidget {
  const DriverMatchedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(activeTripProvider);
    final draft = ref.watch(rideDraftProvider);
    final driver = trip.driver ?? Mock.driver;
    final theme = Theme.of(context);

    return MapSheetScaffold(
      showBack: false,
      mapFraction: 0.38,
      map: MapCanvas(
        pickup: _pickupAt(draft),
        drivers: const [MapDriver(Offset(0.18, 0.32), heading: 1.1)],
        showRoute: false,
      ),
      sheet: SheetSurface(
        scrollable: true,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Driver on the way',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  EtaChip('Arriving in ${trip.etaMin} min'),
                ],
              ),
              const SizedBox(height: 12),
              DriverCard(driver: driver),
              const SizedBox(height: 14),
              TripActionRow(),
              const SizedBox(height: 14),
              TripPinRow(
                pin: Mock.tripPin,
                revealed: trip.pinRevealed,
                onReveal: () =>
                    ref.read(activeTripProvider.notifier).revealPin(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Driver is arriving',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        ref.read(activeTripProvider.notifier).driverArriving();
                        context.go(Routes.driverArriving);
                      },
                    ),
                  ),
                ],
              ),
              Center(
                child: LinkText(
                  'Simulate driver cancel',
                  size: 12,
                  color: context.textSecondary,
                  onTap: () {
                    ref.read(activeTripProvider.notifier).driverCancels();
                    context.go(Routes.driverCancelled);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3.3 — Driver arriving.
class DriverArrivingScreen extends ConsumerWidget {
  const DriverArrivingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(activeTripProvider);
    final draft = ref.watch(rideDraftProvider);
    final driver = trip.driver ?? Mock.driver;
    final theme = Theme.of(context);
    return MapSheetScaffold(
      showBack: false,
      mapFraction: 0.5,
      map: MapCanvas(
        pickup: _pickupAt(draft),
        drivers: const [MapDriver(Offset(0.24, 0.5), heading: 1.3)],
      ),
      sheet: SheetSurface(
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your driver is arriving',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                EtaChip('${trip.etaMin} min away'),
              ],
            ),
            const SizedBox(height: 12),
            DriverCard(driver: driver, compact: true),
            const SizedBox(height: 14),
            TripActionRow(),
            const SizedBox(height: 14),
            SecondaryButton(
              label: 'Share Trip',
              icon: Icons.ios_share_rounded,
              onPressed: () => showToast(
                context,
                'Trip link copied',
                kind: ToastKind.success,
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Driver has arrived',
              onPressed: () {
                ref.read(activeTripProvider.notifier).driverArrived();
                context.go(Routes.driverArrived);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 3.4 — Driver arrived.
class DriverArrivedScreen extends ConsumerWidget {
  const DriverArrivedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(activeTripProvider);
    final draft = ref.watch(rideDraftProvider);
    final driver = trip.driver ?? Mock.driver;
    final theme = Theme.of(context);
    return MapSheetScaffold(
      showBack: false,
      mapFraction: 0.42,
      map: MapCanvas(
        pickup: _pickupAt(draft),
        drivers: [
          MapDriver(_pickupAt(draft) + const Offset(0.03, -0.02), heading: 1.5),
        ],
      ),
      sheet: SheetSurface(
        padding: EdgeInsets.zero,
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your driver has arrived',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DriverCard(driver: driver, compact: true),
                  const SizedBox(height: 14),
                  Text(
                    'Look for a ${driver.vehicle.description.toLowerCase()}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      driver.vehicle.plate,
                      style: AppText.fare(
                        context,
                        size: 34,
                      ).copyWith(letterSpacing: 3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.tint,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pin_rounded,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Share PIN ',
                              style: theme.textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: Mock.tripPin,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const TextSpan(text: ' with driver'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TripActionRow(),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Start Trip',
                    onPressed: () {
                      ref.read(activeTripProvider.notifier).startTrip();
                      context.go(Routes.tripInProgress);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3.5 — Trip in progress (collapsed / expanded sheet, SOS button).
class TripInProgressScreen extends ConsumerStatefulWidget {
  const TripInProgressScreen({super.key});
  @override
  ConsumerState<TripInProgressScreen> createState() =>
      _TripInProgressScreenState();
}

class _TripInProgressScreenState extends ConsumerState<TripInProgressScreen> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider);
    final draft = ref.watch(rideDraftProvider);
    final driver = trip.driver ?? Mock.driver;
    final dest = draft.destination ?? Mock.destination;
    final theme = Theme.of(context);
    final p = _pickupAt(draft);
    final d = _destAt(draft);
    final driverPos = Offset.lerp(p, d, trip.progress)!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapCanvas(
              pickup: p,
              destination: d,
              stops: draft.stops
                  .map((s) => s.at ?? const Offset(0.5, 0.4))
                  .toList(),
              showRoute: true,
              routeProgress: trip.progress,
              drivers: [MapDriver(driverPos, heading: -0.9)],
            ),
          ),
          // Floating top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const RouteDot(color: AppColors.dangerRed, square: true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dest.name,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    EtaChip(
                      trip.progress >= 1 ? 'Arrived' : '${trip.etaMin} min',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SosButton(
                      onTriggered: () => context.push(Routes.sos),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  onVerticalDragEnd: (d) =>
                      setState(() => _expanded = (d.primaryVelocity ?? 0) < 0),
                  child: SheetSurface(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Avatar(name: driver.name, size: 40),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver.name,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: AppColors.accentGold,
                                        ),
                                        Text(
                                          ' ${driver.rating}',
                                          style: theme.textTheme.labelMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PlateNumber(driver.vehicle.plate),
                            ],
                          ),
                          if (_expanded) ...[
                            const SizedBox(height: 16),
                            _Milestones(
                              progress: trip.progress,
                              stops: draft.stops.map((s) => s.name).toList(),
                              destination: dest.name,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.traffic_rounded,
                                    size: 18,
                                    color: AppColors.accentGold,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Third Mainland Bridge is clear · saving ~6 min',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: context.textPrimary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            RouteSummary(
                              pickup: draft.pickup.address,
                              destination: dest.name,
                              stops: draft.stops.map((s) => s.name).toList(),
                              dense: true,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                LinkText(
                                  'Add Stop',
                                  onTap: () => context.push(Routes.search),
                                ),
                                const SizedBox(width: 20),
                                LinkText(
                                  'Change Destination',
                                  onTap: () => context.push(Routes.search),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TripActionRow(),
                          ],
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: trip.progress >= 1
                                ? 'End Trip'
                                : 'Skip to arrival',
                            color: trip.progress >= 1
                                ? AppColors.successTeal
                                : null,
                            onPressed: () {
                              ref.read(activeTripProvider.notifier).complete();
                              context.go(Routes.tripCompleted);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pickup → stops → destination milestone track ("Trip milestones").
class _Milestones extends StatelessWidget {
  const _Milestones({
    required this.progress,
    required this.stops,
    required this.destination,
  });
  final double progress;
  final List<String> stops;
  final String destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = ['Pickup', ...stops, destination];
    final n = labels.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Trip milestones', style: theme.textTheme.titleSmall),
            ),
            StatusBadge(
              progress >= 1 ? 'Arrived' : 'In progress',
              kind: progress >= 1 ? BadgeKind.completed : BadgeKind.inProgress,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < n; i++) ...[
              _MilestoneDot(
                reached: progress >= i / (n - 1) - 0.001,
                last: i == n - 1,
              ),
              if (i < n - 1)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ((progress - i / (n - 1)) * (n - 1)).clamp(0, 1),
                      minHeight: 4,
                      backgroundColor: context.border,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: i == 0
                      ? TextAlign.start
                      : i == n - 1
                      ? TextAlign.end
                      : TextAlign.center,
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MilestoneDot extends StatelessWidget {
  const _MilestoneDot({required this.reached, required this.last});
  final bool reached;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final color = reached
        ? (last ? AppColors.dangerRed : AppColors.primaryBlue)
        : context.border;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: last ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: last ? BorderRadius.circular(3) : null,
        border: Border.all(color: context.surface, width: 2),
      ),
    );
  }
}

/// 3.6 — SOS / Emergency overlay.
class SosScreen extends ConsumerWidget {
  const SosScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = ref.watch(activeTripProvider).driver ?? Mock.driver;
    final theme = Theme.of(context);
    Widget option(
      IconData icon,
      String label, {
      VoidCallback? onTap,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap:
              onTap ??
              () =>
                  showToast(context, '$label — sent', kind: ToastKind.success),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.dangerRed.withValues(alpha: 0.96),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'EMERGENCY',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose an action. Your location is being shared.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 28),
              option(Icons.call_rounded, 'Call Emergency Services (112)'),
              option(Icons.share_location_rounded, 'Share My Location'),
              option(
                Icons.notifications_active_rounded,
                'Alert NaijaMove Safety Team',
              ),
              option(Icons.group_rounded, 'Notify Trusted Contacts'),
              const Spacer(),
              Text(
                '${driver.name} · ${driver.vehicle.plate} · near ${Mock.pickup.address}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: theme.textTheme.labelLarge,
                  ),
                  child: const Text("I'm Safe — Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3.7 — Trip completed.
class TripCompletedScreen extends ConsumerWidget {
  const TripCompletedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(rideDraftProvider);
    final theme = Theme.of(context);
    final dest = draft.destination ?? Mock.destination;
    return MapSheetScaffold(
      showBack: false,
      mapFraction: 0.28,
      map: MapCanvas(
        pickup: _pickupAt(draft),
        destination: _destAt(draft),
        showRoute: true,
        dimmed: true,
      ),
      sheet: SheetSurface(
        scrollable: true,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const SuccessCheck(size: 72),
              const SizedBox(height: 12),
              Text('Trip Complete!', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '${Mock.pickup.address.split(',').first} → ${dest.name}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total paid',
                                style: theme.textTheme.labelMedium,
                              ),
                              Text(
                                naira(Mock.fareEstimate),
                                style: AppText.fare(context, size: 32),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(
                              draft.payment.icon,
                              color: context.textSecondary,
                            ),
                            Text(
                              draft.payment.label,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const FareBreakdown(rows: Mock.fareRows),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(icon: Icons.route_rounded, label: '18.2 km'),
                  _Stat(icon: Icons.timer_outlined, label: '42 min'),
                  _Stat(icon: draft.category.icon, label: draft.category.label),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Rate Your Trip',
                icon: Icons.star_rounded,
                onPressed: () {
                  ref.read(ratingProvider.notifier).reset();
                  context.go(Routes.rate);
                },
              ),
              GhostButton(
                label: 'Skip',
                onPressed: () {
                  ref.read(activeTripProvider.notifier).reset();
                  context.go(Routes.home);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: context.textSecondary, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3.8 — Driver cancelled.
class DriverCancelledScreen extends ConsumerWidget {
  const DriverCancelledScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(rideDraftProvider);
    final dest = draft.destination ?? Mock.destination;
    final theme = Theme.of(context);
    return MapSheetScaffold(
      showBack: false,
      mapFraction: 0.42,
      map: MapCanvas(pickup: _pickupAt(draft)),
      sheet: SheetSurface(
        scrollable: true,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.dangerTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.car_crash_outlined,
                color: AppColors.dangerRed,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text('Your driver cancelled', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              "This happens sometimes. We'll find you another driver.",
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.successTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.successTeal,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "You won't be charged for this cancellation",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.successTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: RouteSummary(
                      pickup: draft.pickup.address,
                      destination: dest.name,
                      dense: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${draft.category.label}\n${naira(Mock.fareEstimate)}',
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Find Another Driver',
              onPressed: () {
                ref.read(activeTripProvider.notifier).startSearch();
                context.go(Routes.searching);
              },
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Change Ride Options',
              onPressed: () => context.go(Routes.rideOptions),
            ),
            GhostButton(
              label: 'Cancel Trip',
              onPressed: () {
                ref.read(activeTripProvider.notifier).reset();
                context.go(Routes.home);
              },
            ),
          ],
        ),
      ),
    );
  }
}
