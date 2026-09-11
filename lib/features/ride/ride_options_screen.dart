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

/// Shared layout for map-top / sheet-bottom ride screens.
class MapSheetScaffold extends StatelessWidget {
  const MapSheetScaffold({
    super.key,
    required this.map,
    required this.sheet,
    this.mapFraction = 0.42,
    this.showBack = true,
    this.topRight,
    this.overlay,
  });
  final Widget map;
  final Widget sheet;
  final double mapFraction;
  final bool showBack;
  final Widget? topRight;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: map),
          if (showBack || topRight != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    if (showBack)
                      MapFab(
                        icon: Icons.arrow_back_rounded,
                        iconColor: context.textPrimary,
                        onPressed: () => context.pop(),
                      ),
                    const Spacer(),
                    ?topRight,
                  ],
                ),
              ),
            ),
          ?overlay,
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(context).height * (1 - mapFraction) + 40,
              ),
              child: sheet,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2.3 — Ride options (vehicle selection) with Now · Schedule · Negotiate tabs.
class RideOptionsScreen extends ConsumerWidget {
  const RideOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(rideDraftProvider);
    final theme = Theme.of(context);
    final dest = draft.destination ?? Mock.destination;

    return MapSheetScaffold(
      map: MapCanvas(
        pickup: draft.pickup.at ?? Mock.pickup.at,
        destination: dest.at ?? Mock.destination.at,
        showRoute: true,
      ),
      sheet: SheetSurface(
        padding: EdgeInsets.zero,
        expand: true,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedTabs(
                    labels: const ['Now', 'Schedule', 'Negotiate'],
                    icons: const [
                      Icons.bolt_rounded,
                      Icons.schedule_rounded,
                      Icons.handshake_outlined,
                    ],
                    selected: 0,
                    onChanged: (i) {
                      if (i == 1) {
                        ref
                            .read(rideDraftProvider.notifier)
                            .setMode(TripMode.scheduled);
                        context.push(Routes.scheduleRide);
                      } else if (i == 2) {
                        ref
                            .read(rideDraftProvider.notifier)
                            .setMode(TripMode.negotiated);
                        context.push(Routes.negotiateRide);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Choose a ride',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'Arrive by 4:24 PM',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: Mock.quotes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final q = Mock.quotes[i];
                  return VehicleCard(
                    quote: q,
                    selected: q.category == draft.category,
                    onTap: () => ref
                        .read(rideDraftProvider.notifier)
                        .setCategory(q.category),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 14,
                        color: AppColors.successTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Fare supports fair driver earnings',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickPayment(context, ref),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Row(
                            children: [
                              Icon(
                                draft.payment.icon,
                                size: 20,
                                color: context.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _shortLabel(draft.payment),
                                  style: theme.textTheme.titleSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: context.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      LinkText(
                        'Add promo code',
                        onTap: () => _promoSheet(context),
                        size: 13,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Request ${draft.category.label}',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.push(Routes.confirmRide),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortLabel(PaymentMethod p) => switch (p.type) {
    PaymentMethodType.card => 'Visa ••4242',
    PaymentMethodType.wallet => 'Wallet',
    PaymentMethodType.cash => 'Cash',
    PaymentMethodType.bankTransfer => p.label,
  };

  void _pickPayment(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pay with', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final pm in [
                ...Mock.paymentMethods,
                const PaymentMethod(
                  id: 'pm_w',
                  type: PaymentMethodType.wallet,
                  label: 'NaijaMove Wallet · ₦ 2,400',
                ),
              ])
                IconRow(
                  icon: pm.icon,
                  title: pm.label,
                  onTap: () {
                    ref.read(rideDraftProvider.notifier).setPayment(pm);
                    Navigator.pop(ctx);
                  },
                  trailing: pm.id == ref.read(rideDraftProvider).payment.id
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryBlue,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _promoSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(ctx).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promo code', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            AppTextField(
              controller: ctrl,
              hint: 'e.g. LAGOS500',
              autofocus: true,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Apply',
              onPressed: () {
                Navigator.pop(ctx);
                showToast(
                  context,
                  'Promo ${ctrl.text.toUpperCase()} applied',
                  kind: ToastKind.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Vehicle category card with selected state and optional surge badge.
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.quote,
    required this.selected,
    required this.onTap,
  });
  final FareQuote quote;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected ? context.tint : context.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? AppColors.primaryBlue : context.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 76,
                  color: selected ? AppColors.primaryBlue : Colors.transparent,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? context.surface : context.tint,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    quote.category.icon,
                    color: AppColors.primaryBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              quote.category.label,
                              style: theme.textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (quote.surge != null) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'High demand in your area',
                              triggerMode: TooltipTriggerMode.tap,
                              child: StatusBadge(
                                '${quote.surge}× surge',
                                kind: BadgeKind.surge,
                                icon: Icons.bolt_rounded,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: context.textSecondary,
                          ),
                          Text(
                            ' ${quote.category.seats} seats',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: context.bg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: context.border),
                            ),
                            child: Text(
                              '${quote.etaMin} min',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                    nairaRange(quote.min, quote.max),
                    style: AppText.fare(
                      context,
                      size: 15,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
