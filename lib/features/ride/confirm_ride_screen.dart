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
import 'ride_options_screen.dart';

/// 2.4 — Confirm ride. Breakdown open by default on first booking, collapsed on repeat.
class ConfirmRideScreen extends ConsumerStatefulWidget {
  const ConfirmRideScreen({super.key});
  @override
  ConsumerState<ConfirmRideScreen> createState() => _ConfirmRideScreenState();
}

class _ConfirmRideScreenState extends ConsumerState<ConfirmRideScreen> {
  bool? _expanded;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(rideDraftProvider);
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final dest = draft.destination ?? Mock.destination;
    final expanded = _expanded ?? !session.hasTrips;

    return MapSheetScaffold(
      mapFraction: 0.32,
      map: MapCanvas(
        pickup: draft.pickup.at ?? Mock.pickup.at,
        destination: dest.at ?? Mock.destination.at,
        stops: draft.stops.map((s) => s.at ?? const Offset(0.5, 0.4)).toList(),
        showRoute: true,
      ),
      sheet: SheetSurface(
        scrollable: true,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RouteSummary(
                pickup: draft.pickup.address,
                destination: dest.name,
                stops: draft.stops.map((s) => s.name).toList(),
                onEditPickup: () => context.pop(),
                onEditDestination: () => context.pop(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              Row(
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
                          '${draft.category.seats} seats · Toyota Corolla or similar',
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    draft.quote.etaMin <= 3 ? 'Fastest' : 'Best value',
                    kind: BadgeKind.info,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated fare',
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(
                          naira(Mock.fareEstimate),
                          style: AppText.fare(context, size: 32),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Price locked',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Breakdown accordion
              Container(
                decoration: BoxDecoration(
                  color: context.bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expanded = !expanded),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Fare breakdown',
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: expanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: const Padding(
                        padding: EdgeInsets.fromLTRB(14, 0, 14, 6),
                        child: FareBreakdown(rows: Mock.fareRows),
                      ),
                      secondChild: const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    draft.payment.icon,
                    size: 20,
                    color: context.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      draft.payment.label,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        Text('Switch', style: theme.textTheme.labelMedium),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: context.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Free cancellation for 2 min',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Confirm Ride',
                onPressed: () {
                  ref.read(activeTripProvider.notifier).startSearch();
                  context.go(Routes.searching);
                },
              ),
              GhostButton(
                label: 'Cancel',
                onPressed: () => context.go(Routes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
