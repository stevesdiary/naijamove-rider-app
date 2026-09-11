import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../trip/trip_widgets.dart';

const _ratingLabels = ['Terrible', 'Bad', 'Okay', 'Good', 'Excellent'];

List<String> _chipsFor(int stars) => switch (stars) {
  5 => const [
    'Great driver',
    'Clean car',
    'On time',
    'Safe driving',
    'Friendly',
  ],
  3 ||
  4 => const ['Late arrival', 'Route issue', 'Car condition', 'Communication'],
  1 || 2 => const [
    'Unsafe driving',
    'Wrong route',
    'Rude behaviour',
    'Car condition',
    'No show',
  ],
  _ => const [],
};

/// 10.1 — Post-trip rating (Step 1 of 2).
class PostTripRatingScreen extends ConsumerStatefulWidget {
  const PostTripRatingScreen({super.key});
  @override
  ConsumerState<PostTripRatingScreen> createState() =>
      _PostTripRatingScreenState();
}

class _PostTripRatingScreenState extends ConsumerState<PostTripRatingScreen> {
  final _comment = TextEditingController();
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(ratingProvider);
    final driver = ref.watch(activeTripProvider).driver ?? Mock.driver;
    final theme = Theme.of(context);
    void skip() {
      ref.read(sessionProvider.notifier).dismissPendingRating();
      ref.read(activeTripProvider.notifier).reset();
      context.go(Routes.home);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        title: const StepProgress(step: 1, total: 2),
        actions: [TextButton(onPressed: skip, child: const Text('Skip'))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        Avatar(name: driver.name, size: 80),
                        const SizedBox(height: 10),
                        Text(driver.name, style: theme.textTheme.headlineSmall),
                        Text(
                          '${driver.vehicle.description} · ${driver.vehicle.plate}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Victoria Island → ${Mock.destination.name}',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'How was your ride with ${driver.firstName}?',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: StarRating(
                      value: rating.stars,
                      onChanged: (v) =>
                          ref.read(ratingProvider.notifier).setStars(v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 22,
                    child: Center(
                      child: rating.stars == 0
                          ? Text(
                              'Tap a star',
                              style: theme.textTheme.labelMedium,
                            )
                          : Text(
                              _ratingLabels[rating.stars - 1],
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                    ),
                  ),
                  if (rating.stars > 0) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        rating.stars == 5
                            ? 'What went well?'
                            : 'What could be better?',
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final c in _chipsFor(rating.stars))
                          SelectChip(
                            label: c,
                            selected: rating.tags.contains(c),
                            onTap: () =>
                                ref.read(ratingProvider.notifier).toggleTag(c),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _comment,
                      hint: 'Tell us more (optional)',
                      maxLines: 3,
                      maxLength: 200,
                      onChanged: (v) =>
                          ref.read(ratingProvider.notifier).setComment(v),
                    ),
                    if (rating.stars <= 2) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: LinkText(
                          'Report a problem with this driver',
                          color: AppColors.dangerRed,
                          onTap: () => context.push(Routes.reportDriver),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Next',
                    onPressed: rating.stars == 0
                        ? null
                        : () => context.push(Routes.tip),
                  ),
                  GhostButton(label: 'Skip', onPressed: skip),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 10.2 — Tip your driver (Step 2 of 2).
class TipDriverScreen extends ConsumerStatefulWidget {
  const TipDriverScreen({super.key});
  @override
  ConsumerState<TipDriverScreen> createState() => _TipDriverScreenState();
}

class _TipDriverScreenState extends ConsumerState<TipDriverScreen> {
  bool _custom = false;
  final _customCtrl = TextEditingController();
  static const _amounts = [100, 200, 500, 1000];

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _finish(int? tip) {
    ref.read(ratingProvider.notifier).setTip(tip);
    ref.read(sessionProvider.notifier).dismissPendingRating();
    context.go(Routes.ratingDone);
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(ratingProvider);
    final driver = ref.watch(activeTripProvider).driver ?? Mock.driver;
    final theme = Theme.of(context);
    final tip = _custom
        ? int.tryParse(_customCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : rating.tip;

    return Scaffold(
      appBar: AppBar(title: const StepProgress(step: 2, total: 2)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Avatar(name: driver.name, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: theme.textTheme.titleMedium,
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Leave a tip for ${driver.firstName}?',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 16,
                        color: AppColors.accentGold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '100% goes directly to your driver',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: [
                      for (final a in _amounts)
                        _TipChip(
                          label: naira(a),
                          selected: !_custom && rating.tip == a,
                          onTap: () => setState(() {
                            _custom = false;
                            ref.read(ratingProvider.notifier).setTip(a);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TipChip(
                    label: 'Custom amount',
                    selected: _custom,
                    dashed: true,
                    onTap: () => setState(() => _custom = true),
                  ),
                  if (_custom) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _customCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 6),
                        child: Text(
                          '₦',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card_rounded,
                        size: 16,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Charged to Visa ••4242',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: tip == null || tip <= 0
                        ? 'Send Tip'
                        : 'Send ${naira(tip)} Tip',
                    icon: Icons.volunteer_activism_rounded,
                    onPressed: tip == null || tip <= 0
                        ? null
                        : () => _finish(tip),
                  ),
                  GhostButton(
                    label: 'No thanks',
                    onPressed: () => _finish(null),
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

class _TipChip extends StatelessWidget {
  const _TipChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dashed = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dashed;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryBlue : context.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? AppColors.primaryBlue : context.border,
          width: dashed ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: 60,
          child: Center(
            child: Text(
              label,
              style: AppText.fare(
                context,
                size: 18,
                weight: FontWeight.w700,
              ).copyWith(color: selected ? Colors.white : context.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// 10.3 — Rating submitted confirmation (auto-dismisses after 4s).
class RatingSubmittedScreen extends ConsumerStatefulWidget {
  const RatingSubmittedScreen({super.key});
  @override
  ConsumerState<RatingSubmittedScreen> createState() =>
      _RatingSubmittedScreenState();
}

class _RatingSubmittedScreenState extends ConsumerState<RatingSubmittedScreen> {
  Timer? _timer;
  int _left = 4;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left <= 1) {
        t.cancel();
        _goHome();
      } else {
        setState(() => _left--);
      }
    });
  }

  void _goHome() {
    _timer?.cancel();
    ref.read(activeTripProvider.notifier).reset();
    ref.read(ratingProvider.notifier).reset();
    if (mounted) context.go(Routes.home);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(ratingProvider);
    final driver = ref.watch(activeTripProvider).driver ?? Mock.driver;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const SuccessCheck(),
              const SizedBox(height: 24),
              Text(
                'Thanks for your feedback!',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your rating helps keep NaijaMove safe and reliable',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (rating.tip != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${naira(rating.tip!)} tip sent to ${driver.firstName} ✓',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.successTeal,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Avatar(name: driver.name, size: 40),
              const SizedBox(height: 6),
              StarRating(value: rating.stars, size: 20, spacing: 2),
              const Spacer(),
              PrimaryButton(
                label: 'Book Another Ride',
                onPressed: () {
                  _timer?.cancel();
                  ref.read(activeTripProvider.notifier).reset();
                  ref.read(rideDraftProvider.notifier).reset();
                  context.go(Routes.home);
                  context.push(Routes.search);
                },
              ),
              GhostButton(label: 'Go Home', onPressed: _goHome),
              Text(
                'Returning home in ${_left}s',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 10.5 — Driver public profile.
class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key, required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = Mock.trips
        .map((t) => t.driver)
        .whereType<Driver>()
        .firstWhere((d) => d.id == driverId, orElse: () => Mock.driver);
    final active = ref.watch(activeTripProvider).status;
    final tripActive =
        active == TripStatus.matched ||
        active == TripStatus.driverArriving ||
        active == TripStatus.driverArrived ||
        active == TripStatus.inProgress;
    final theme = Theme.of(context);
    final v = driver.vehicle;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Avatar(name: driver.name, size: 96),
                const SizedBox(height: 12),
                Text(driver.name, style: theme.textTheme.headlineMedium),
                Text(
                  'Member since ${driver.memberSince}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final b in ['Identity', 'Licence', 'Vehicle'])
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successTint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.successTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              b,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.successTeal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Row(
              children: [
                _StatCol(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.accentGold,
                  value: '${driver.rating}',
                  label: 'Rating',
                ),
                _StatCol(
                  icon: Icons.directions_car_rounded,
                  value: driver.trips.toString().replaceAllMapped(
                    RegExp(r'(\d)(?=(\d{3})+$)'),
                    (m) => '${m[1]},',
                  ),
                  label: 'Trips',
                ),
                if (driver.topDriver)
                  const _StatCol(
                    icon: Icons.emoji_events_rounded,
                    iconColor: AppColors.accentGold,
                    value: 'Top',
                    label: 'Driver',
                  ),
              ],
            ),
          ),
          if (driver.bio != null) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(driver.bio!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${driver.rating}',
                      style: AppText.fare(context, size: 36),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        '/ 5',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const StarDistribution(
                  percentages: Mock.driverStarDistribution,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Top compliments'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, n) in Mock.driverCompliments)
                SelectChip(label: '$label ($n)', selected: true),
            ],
          ),
          const SizedBox(height: 20),
          SectionLabel(
            'Recent reviews',
            trailing: LinkText('Show all reviews', size: 13, onTap: () {}),
          ),
          for (final r in Mock.driverReviews) _ReviewTile(review: r),
          const SizedBox(height: 12),
          const SectionLabel('Vehicle'),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.tint,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(v.category.icon, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${v.make} ${v.model} ${v.year}',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(v.colour, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PlateNumber(v.plate),
                    const SizedBox(height: 4),
                    StatusBadge(v.category.label, kind: BadgeKind.info),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: tripActive
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Call',
                        icon: Icons.call_rounded,
                        onPressed: () => showToast(context, 'Calling driver…'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Chat',
                        icon: Icons.chat_bubble_rounded,
                        onPressed: () => context.push(Routes.driverChat),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? AppColors.primaryBlue),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, this.showComment = true});
  final Review review;
  final bool showComment;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Rider', style: theme.textTheme.labelMedium),
                const SizedBox(width: 8),
                StarRating(value: review.stars, size: 14, spacing: 0),
                const Spacer(),
                Text(relative(review.date), style: theme.textTheme.labelSmall),
              ],
            ),
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in review.tags)
                    SelectChip(label: t, selected: true),
                ],
              ),
            ],
            if (showComment && review.comment != null) ...[
              const SizedBox(height: 8),
              Text(
                '"${review.comment}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 10.6 — My rider rating.
class MyRatingScreen extends StatelessWidget {
  const MyRatingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const factors = [
      (
        'Cancellation rate',
        'Cancelling after a driver accepts can lower your rating.',
      ),
      (
        'Punctuality at pickup',
        'Being at the pickup point when your driver arrives keeps things moving.',
      ),
      (
        'Respectful behaviour',
        'Drivers rate courtesy and how you treat their vehicle.',
      ),
      (
        'Payment reliability',
        'Failed card payments or unpaid cash fares affect your score.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Your Rider Rating')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accentGold,
                      size: 44,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${Mock.riderRating}',
                      style: AppText.fare(context, size: 48),
                    ),
                  ],
                ),
                Text(
                  'Based on ${Mock.riderTrips} driver ratings',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                const StarDistribution(percentages: Mock.riderStarDistribution),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('What affects your rating'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, (title, body)) in factors.indexed) ...[
                  ExpansionTile(
                    initiallyExpanded: i == 0,
                    shape: const Border(),
                    title: Text(title, style: theme.textTheme.titleSmall),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    children: [Text(body, style: theme.textTheme.bodySmall)],
                  ),
                  if (i < factors.length - 1) const Divider(),
                ],
              ],
            ),
          ),
          if (Mock.riderRating < 4.5) ...[
            const SizedBox(height: 20),
            const SectionLabel('Tips to improve'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in [
                    'Cancel within the 2-minute free window if plans change',
                    'Wait at the pin, not inside the building',
                    'Keep your payment method up to date',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $t', style: theme.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const SectionLabel('Recent feedback from drivers'),
          for (final r in Mock.riderFeedback)
            _ReviewTile(review: r, showComment: false),
          Text(
            'Driver comments are private and not shown here.',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          Center(
            child: LinkText(
              'Learn how ratings work',
              onTap: () => context.push(Routes.faq),
            ),
          ),
        ],
      ),
    );
  }
}

/// 10.7 — Report a driver / issue.
class ReportDriverScreen extends StatefulWidget {
  const ReportDriverScreen({super.key, this.trip});
  final Trip? trip;
  @override
  State<ReportDriverScreen> createState() => _ReportDriverScreenState();
}

class _ReportDriverScreenState extends State<ReportDriverScreen> {
  static const _categories = [
    (Icons.car_crash_outlined, 'Unsafe or reckless driving'),
    (Icons.alt_route_rounded, 'Took wrong route intentionally'),
    (
      Icons.sentiment_very_dissatisfied_rounded,
      'Rude or threatening behaviour',
    ),
    (Icons.credit_card_off_rounded, 'Payment dispute'),
    (Icons.person_off_rounded, 'Driver did not show up'),
    (Icons.pin_rounded, 'Trip PIN not used'),
    (Icons.shield_outlined, 'Safety concern or harassment'),
    (Icons.help_outline_rounded, 'Other'),
  ];
  int? _selected;
  final _desc = TextEditingController();
  int _photos = 1;
  bool _submitted = false;

  bool get _descRequired => _selected == 6 || _selected == 7;
  bool get _canSubmit =>
      _selected != null && (!_descRequired || _desc.text.trim().length >= 10);

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = widget.trip ?? Mock.currentTrip;
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report an Issue')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const SuccessCheck(size: 80),
              const SizedBox(height: 20),
              Text('Report submitted', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Our safety team will review this within 24 hours',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('Case reference', style: theme.textTheme.labelMedium),
              Text('NM-2026-00851', style: AppText.mono(context, size: 22)),
              const Spacer(),
              PrimaryButton(
                label: 'Done',
                onPressed: () => context.go(Routes.home),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Avatar(
                          name: trip.driver?.name ?? Mock.driver.name,
                          size: 40,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${trip.driver?.name ?? Mock.driver.name} · ${trip.driver?.vehicle.plate ?? Mock.vehicle.plate}\n${dayMonthTime(trip.date)} · ${trip.pickup.address.split(',').first} → ${trip.destination.name}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('What happened?', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  for (final (i, (icon, label)) in _categories.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        radius: AppRadius.md,
                        borderColor: _selected == i
                            ? AppColors.primaryBlue
                            : null,
                        color: _selected == i ? context.tint : null,
                        onTap: () => setState(() => _selected = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: IconRow(
                            icon: icon,
                            title: label,
                            dense: true,
                            iconColor: i == 6 ? AppColors.dangerRed : null,
                            iconBg: i == 6 ? AppColors.dangerTint : null,
                            trailing: Icon(
                              _selected == i
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: _selected == i
                                  ? AppColors.primaryBlue
                                  : context.border,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: _descRequired
                        ? 'Describe what happened *'
                        : 'Describe what happened',
                    hint: 'Describe what happened',
                    controller: _desc,
                    maxLines: 4,
                    maxLength: 500,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Attach evidence (optional)'),
                  Row(
                    children: [
                      for (var i = 0; i < _photos; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: context.tint,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.image_rounded,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _photos--),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryDark,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_photos < 3)
                        GestureDetector(
                          onTap: () => setState(() => _photos++),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: context.border,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Up to 3 photos', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DestructiveButton(
                    label: 'Submit Report',
                    onPressed: _canSubmit
                        ? () => setState(() => _submitted = true)
                        : null,
                  ),
                  GhostButton(label: 'Cancel', onPressed: () => context.pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
