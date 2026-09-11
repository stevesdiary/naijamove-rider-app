import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/map_canvas.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// 5.1 — Trip history (Trips tab).
class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});
  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  int _tab = 0;
  static const _tabs = ['All', 'Completed', 'Cancelled', 'Scheduled'];

  List<Trip> get _filtered => switch (_tab) {
    1 => Mock.trips.where((t) => t.status == TripStatus.completed).toList(),
    2 => Mock.trips.where((t) => t.status == TripStatus.cancelled).toList(),
    3 => Mock.trips.where((t) => t.mode == TripMode.scheduled).toList(),
    _ => Mock.trips.where((t) => t.mode != TripMode.scheduled).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final hasTrips = ref.watch(sessionProvider.select((s) => s.hasTrips));
    final items = _filtered;
    final groups = <String, List<Trip>>{};
    for (final t in items) {
      groups.putIfAbsent(monthYear(t.date), () => []).add(t);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Trips'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          FilterTabs(
            labels: _tabs,
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const Divider(),
          Expanded(
            child: !hasTrips || items.isEmpty
                ? EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: _tab == 3 ? 'No scheduled rides' : 'No trips yet',
                    subtitle: _tab == 3
                        ? 'Book ahead from the Schedule tab when choosing a ride.'
                        : 'Book your first ride!',
                    ctaLabel: 'Book a Ride',
                    onCta: () => context.go(Routes.home),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_tab != 3) ...[
                        _MonthSummary(trips: items),
                        const SizedBox(height: 16),
                      ],
                      for (final entry in groups.entries) ...[
                        SectionLabel(
                          entry.key,
                          trailing: Text(
                            '${entry.value.length} ride${entry.value.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        for (final t in entry.value) ...[
                          _TripCard(trip: t, scheduledTab: _tab == 3),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.scheduledTab});
  final Trip trip;
  final bool scheduledTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = switch (trip.status) {
      TripStatus.completed => const StatusBadge(
        'Completed',
        kind: BadgeKind.completed,
      ),
      TripStatus.cancelled => const StatusBadge(
        'Cancelled',
        kind: BadgeKind.cancelled,
      ),
      TripStatus.inProgress => const StatusBadge(
        'In Progress',
        kind: BadgeKind.inProgress,
      ),
      _ =>
        trip.mode == TripMode.scheduled
            ? const StatusBadge('Scheduled', kind: BadgeKind.scheduled)
            : const StatusBadge('Requested', kind: BadgeKind.info),
    };
    final cancelled = trip.status == TripStatus.cancelled;
    final card = AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(Routes.receipt(trip.id)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: MapCanvas(
                    pickup: trip.pickup.at,
                    destination: trip.destination.at,
                    showRoute: true,
                    dimmed: cancelled,
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: StatusBadge(trip.category.label, kind: BadgeKind.info),
                ),
                Positioned(right: 10, top: 10, child: badge),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.mode == TripMode.scheduled
                              ? fullDate(trip.date)
                              : dayMonthTime(trip.date),
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 6),
                        RouteSummary(
                          pickup: trip.pickup.name == 'Current location'
                              ? trip.pickup.address
                              : trip.pickup.name,
                          destination: trip.destination.name,
                          stops: trip.stops.map((s) => s.name).toList(),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Fare', style: theme.textTheme.labelSmall),
                      Text(
                        naira(trip.fare),
                        style: AppText.fare(context, size: 18).copyWith(
                          decoration: cancelled
                              ? TextDecoration.lineThrough
                              : null,
                          color: cancelled ? context.textSecondary : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (!scheduledTab) return card;
    return Dismissible(
      key: ValueKey(trip.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.dangerTint,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, color: AppColors.dangerRed),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Cancel Booking',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.dangerRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => showToast(context, 'Scheduled booking cancelled'),
      child: card,
    );
  }
}

/// Distance / spend roll-up for the visible trips.
class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.trips});
  final List<Trip> trips;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = trips.where((t) => t.status == TripStatus.completed).toList();
    final km = done.fold<double>(0, (a, t) => a + t.distanceKm);
    final spent = done.fold<int>(0, (a, t) => a + t.fare);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAGOS CITY MILES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${km.toStringAsFixed(1)} km',
                  style: AppText.fare(
                    context,
                    size: 26,
                  ).copyWith(color: Colors.white),
                ),
                Text(
                  'across ${done.length} completed trip${done.length == 1 ? '' : 's'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  naira(spent),
                  style: AppText.fare(
                    context,
                    size: 16,
                    weight: FontWeight.w600,
                  ).copyWith(color: Colors.white),
                ),
                Text(
                  'spent',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
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

/// 5.2 — Trip receipt.
class TripReceiptScreen extends StatelessWidget {
  const TripReceiptScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context) {
    final trip = Mock.trips.firstWhere(
      (t) => t.id == tripId,
      orElse: () => Mock.currentTrip,
    );
    final theme = Theme.of(context);
    final cancelled = trip.status == TripStatus.cancelled;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Receipt'),
        actions: [
          IconButton(
            onPressed: () =>
                showToast(context, 'PDF receipt is being prepared'),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              height: 160,
              child: MapCanvas(
                pickup: trip.pickup.at,
                destination: trip.destination.at,
                showRoute: true,
                dimmed: cancelled,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fullDate(trip.date),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    cancelled
                        ? const StatusBadge(
                            'Cancelled',
                            kind: BadgeKind.cancelled,
                          )
                        : const StatusBadge(
                            'Completed',
                            kind: BadgeKind.completed,
                          ),
                  ],
                ),
                const SizedBox(height: 14),
                RouteSummary(
                  pickup: trip.pickup.address,
                  destination: trip.destination.name,
                  stops: trip.stops.map((s) => s.name).toList(),
                ),
                if (trip.driver != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  InkWell(
                    onTap: () =>
                        context.push(Routes.driverProfile(trip.driver!.id)),
                    child: Row(
                      children: [
                        Avatar(name: trip.driver!.name, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.driver!.name,
                                style: theme.textTheme.titleSmall,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: AppColors.accentGold,
                                  ),
                                  Expanded(
                                    child: Text(
                                      ' ${trip.driver!.rating} · ${trip.driver!.vehicle.description} · ${trip.driver!.vehicle.plate}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fare breakdown', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                FareBreakdown(
                  rows: cancelled
                      ? const [('Cancellation fee', '₦ 0')]
                      : Mock.fareRows,
                  total: naira(cancelled ? 0 : trip.fare),
                  totalLabel: cancelled ? 'Charged' : 'Total paid',
                ),
                const SizedBox(height: 14),
                if (trip.paymentMethod != null)
                  Row(
                    children: [
                      Icon(
                        trip.paymentMethod!.icon,
                        size: 18,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trip.paymentMethod!.label,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 18,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ref ${trip.reference ?? '—'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.route_rounded,
                      size: 18,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${trip.distanceKm} km · ${trip.durationMin} min',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: LinkText(
              'Report an Issue',
              onTap: () => context.push(Routes.reportDriver, extra: trip),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: LinkText(
              'Get help with this trip',
              color: context.textSecondary,
              onTap: () => context.push(Routes.support),
            ),
          ),
        ],
      ),
    );
  }
}
