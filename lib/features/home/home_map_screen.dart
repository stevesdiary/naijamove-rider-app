import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/map_canvas.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../rating/pending_rating_card.dart';

/// 2.1 — Home map (idle). Map is the hero; collapsed sheet at the bottom.
class HomeMapScreen extends ConsumerWidget {
  const HomeMapScreen({super.key});

  static const _drivers = [
    MapDriver(Offset(0.22, 0.28), heading: 0.6),
    MapDriver(Offset(0.58, 0.22), heading: -1.2),
    MapDriver(Offset(0.42, 0.45), heading: 2.4),
    MapDriver(Offset(0.78, 0.4), heading: 0.2),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final unread = Mock.notifications.where((n) => n.unread).isNotEmpty;

    void goSearch() {
      ref.read(rideDraftProvider.notifier).reset();
      context.push(Routes.search);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: MapCanvas(
            drivers: _drivers,
            currentLocation: Mock.pickup.at,
            heatmap: true,
          ),
        ),
        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const BrandLockup(size: 24),
                ),
                const Spacer(),
                Stack(
                  children: [
                    MapFab(
                      icon: Icons.notifications_outlined,
                      onPressed: () => context.push(Routes.notifications),
                    ),
                    if (unread)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Bottom stack: pending rating card + my-location FAB + sheet
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: MapFab(
                    icon: Icons.my_location_rounded,
                    onPressed: () {},
                  ),
                ),
              ),
              if (session.pendingRating)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: PendingRatingCard(
                    driver: Mock.driver,
                    onRate: () => context.push(Routes.rate),
                    onDismiss: () => ref
                        .read(sessionProvider.notifier)
                        .dismissPendingRating(),
                  ),
                ),
              SheetSurface(
                safeBottom: false,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    GestureDetector(
                      onTap: goSearch,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: context.bg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: context.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Where to?',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push(Routes.savedPlaces),
                              child: Icon(
                                Icons.star_outline_rounded,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Wallet row
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: context.tint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wallet balance',
                                style: theme.textTheme.labelSmall,
                              ),
                              Text(
                                naira(session.walletBalance),
                                style: AppText.fare(
                                  context,
                                  size: 16,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LinkText(
                          'Top Up',
                          onTap: () => context.push(Routes.topUp),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick-action chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SelectChip(
                            label: 'Home',
                            icon: Icons.home_rounded,
                            onTap: () => _quickRide(context, ref, Mock.home),
                          ),
                          const SizedBox(width: 8),
                          SelectChip(
                            label: 'Work',
                            icon: Icons.work_rounded,
                            onTap: () => _quickRide(context, ref, Mock.work),
                          ),
                          const SizedBox(width: 8),
                          SelectChip(
                            label: 'Saved',
                            icon: Icons.star_rounded,
                            onTap: () => context.push(Routes.savedPlaces),
                          ),
                          const SizedBox(width: 8),
                          SelectChip(
                            label: 'Book via WhatsApp',
                            icon: Icons.chat_rounded,
                            onTap: () => context.push(Routes.whatsapp),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (session.hasTrips) ...[
                      const SectionLabel('Recent destinations'),
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: Mock.recents.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => _RecentCard(
                            place: Mock.recents[i],
                            onTap: () =>
                                _quickRide(context, ref, Mock.recents[i]),
                          ),
                        ),
                      ),
                    ] else
                      _FirstRideCard(onBook: goSearch),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _quickRide(BuildContext context, WidgetRef ref, Place destination) {
    ref.read(rideDraftProvider.notifier)
      ..reset()
      ..setDestination(destination);
    context.push(Routes.rideOptions);
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        width: 180,
        child: Row(
          children: [
            Icon(Icons.history_rounded, color: context.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    place.address,
                    style: theme.textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// First-ride empty state (zero trip history).
class _FirstRideCard extends StatelessWidget {
  const _FirstRideCard({required this.onBook});
  final VoidCallback onBook;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      color: context.tint,
      borderColor: Colors.transparent,
      child: Row(
        children: [
          const Icon(
            Icons.directions_car_rounded,
            size: 44,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where are you headed?',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Book your first NaijaMove ride',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 140,
                  child: PrimaryButton(label: 'Book a Ride', onPressed: onBook),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
