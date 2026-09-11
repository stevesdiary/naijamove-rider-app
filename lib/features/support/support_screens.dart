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
import '../../core/widgets/map_canvas.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import 'chat_widgets.dart';

/// 11.1 — Help & Support home.
class SupportHomeScreen extends ConsumerWidget {
  const SupportHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final openCase = Mock.cases.firstWhere((c) => c.status == CaseStatus.open);
    void startCase(String category, {Trip? trip}) {
      ref.read(caseDraftProvider.notifier)
        ..reset()
        ..setCategory(category)
        ..setTrip(trip);
      context.push(Routes.issueCategory);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(
            hint: 'Search help topics',
            prefix: const Icon(Icons.search_rounded),
            onTap: () => context.push(Routes.faq),
            readOnly: true,
          ),
          const SizedBox(height: 16),
          // Active case banner
          AppCard(
            color: context.tint,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => context.push(Routes.caseDetail(openCase.reference)),
            child: Row(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${openCase.reference} · ${openCase.title}',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        'Updated ${relative(openCase.updated)}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                caseBadge(openCase.status),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              for (final (icon, label) in [
                (Icons.directions_car_rounded, 'Trip issue'),
                (Icons.credit_card_rounded, 'Payment problem'),
                (Icons.shield_rounded, 'Safety concern'),
                (Icons.person_rounded, 'Account issue'),
              ])
                AppCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => startCase(label),
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.primaryBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(label, style: theme.textTheme.titleSmall),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionLabel('Get help for a recent trip'),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final t = Mock.trips
                    .where((t) => t.mode != TripMode.scheduled)
                    .elementAt(i);
                return AppCard(
                  padding: const EdgeInsets.all(10),
                  onTap: () => startCase('Trip issue', trip: t),
                  child: SizedBox(
                    width: 200,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: MapCanvas(
                              pickup: t.pickup.at,
                              destination: t.destination.at,
                              showRoute: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.destination.name,
                                style: theme.textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${dayMonth(t.date)} · ${naira(t.fare)}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Chat with Support',
            icon: Icons.chat_bubble_rounded,
            onPressed: () =>
                context.push(Routes.caseDetail(openCase.reference)),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Call Support',
            icon: Icons.call_rounded,
            onPressed: () => showToast(context, 'Calling 0700-NAIJAMOVE…'),
          ),
          const SizedBox(height: 8),
          Center(
            child: LinkText(
              'My Cases',
              onTap: () => context.push(Routes.myCases),
            ),
          ),
          const SizedBox(height: 16),
          SectionLabel(
            'Frequently asked questions',
            trailing: LinkText(
              'View all FAQs',
              size: 13,
              onTap: () => context.push(Routes.faq),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, q) in Mock.faqs.indexed) ...[
                  ListTile(
                    title: Text(
                      q,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: context.textSecondary,
                    ),
                    onTap: () => context.push(Routes.faq),
                  ),
                  if (i < Mock.faqs.length - 1) const Divider(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 11.2 — Select issue category.
class IssueCategoryScreen extends ConsumerWidget {
  const IssueCategoryScreen({super.key});

  static const categories = [
    (Icons.person_off_rounded, "My driver didn't show up"),
    (Icons.alt_route_rounded, 'Driver took the wrong route'),
    (Icons.credit_card_rounded, 'I was charged incorrectly'),
    (Icons.currency_exchange_rounded, "I didn't receive my refund"),
    (Icons.shield_rounded, 'I felt unsafe during my trip'),
    (Icons.search_rounded, 'Lost item in vehicle'),
    (Icons.lock_outline_rounded, 'Account or login issue'),
    (Icons.chat_bubble_outline_rounded, 'Other — describe your issue'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(caseDraftProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('What do you need help with?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (draft.trip != null) ...[
            _TripContextCard(
              trip: draft.trip!,
              onChange: () =>
                  ref.read(caseDraftProvider.notifier).setTrip(null),
            ),
            const SizedBox(height: 16),
          ],
          for (final (i, (icon, label)) in categories.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                radius: AppRadius.md,
                child: IconRow(
                  icon: icon,
                  title: label,
                  iconColor: i == 4 ? AppColors.dangerRed : null,
                  iconBg: i == 4 ? AppColors.dangerTint : null,
                  onTap: () {
                    ref.read(caseDraftProvider.notifier).setCategory(label);
                    context.push(Routes.issueForm);
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: LinkText(
              'Browse FAQs instead',
              onTap: () => context.push(Routes.faq),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Most issues are resolved within 2 hours',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripContextCard extends StatelessWidget {
  const _TripContextCard({
    required this.trip,
    this.onChange,
    this.compact = false,
  });
  final Trip trip;
  final VoidCallback? onChange;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          if (!compact)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: MapCanvas(
                  pickup: trip.pickup.at,
                  destination: trip.destination.at,
                  showRoute: true,
                ),
              ),
            ),
          if (!compact) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.pickup.address.split(',').first} → ${trip.destination.name}',
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${dayMonthTime(trip.date)} · ${naira(trip.fare)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onChange != null) LinkText('Change', size: 13, onTap: onChange),
        ],
      ),
    );
  }
}

/// 11.3 — Issue detail form (dynamic fields per category).
class IssueFormScreen extends ConsumerStatefulWidget {
  const IssueFormScreen({super.key});
  @override
  ConsumerState<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends ConsumerState<IssueFormScreen> {
  final _desc = TextEditingController();
  final _expected = TextEditingController(text: '1200');
  final _actual = TextEditingController(text: '1350');
  final _item = TextEditingController();
  int _photos = 0;
  int _severity = 1;

  @override
  void dispose() {
    _desc.dispose();
    _expected.dispose();
    _actual.dispose();
    _item.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(caseDraftProvider);
    final theme = Theme.of(context);
    final cat = draft.category ?? 'Other';
    final isCharge = cat.contains('charged');
    final isLost = cat.contains('Lost');
    final isSafety = cat.contains('unsafe') || cat.contains('Safety');
    final title = isCharge
        ? 'Incorrect Charge'
        : isLost
        ? 'Lost Item'
        : isSafety
        ? 'Safety Concern'
        : cat.split(' — ').first;
    final canSubmit =
        _desc.text.trim().length >= (isSafety ? 10 : 1) || isCharge;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (draft.trip != null) ...[
                    _TripContextCard(trip: draft.trip!, compact: true),
                    const SizedBox(height: 16),
                  ],
                  if (isCharge) ...[
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Expected amount',
                            controller: _expected,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            prefix: const _Naira(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Actual amount',
                            controller: _actual,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            prefix: const _Naira(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLost) ...[
                    AppTextField(
                      label: 'Item description',
                      hint: 'e.g. Black umbrella with wooden handle',
                      controller: _item,
                    ),
                    const SizedBox(height: 12),
                    const AppTextField(
                      label: 'Where did you leave it?',
                      hint: 'Back seat, boot…',
                    ),
                    const SizedBox(height: 12),
                    const SectionLabel('Contact preference'),
                    Wrap(
                      spacing: 8,
                      children: const [
                        SelectChip(label: 'Call', selected: true),
                        SelectChip(label: 'WhatsApp'),
                        SelectChip(label: 'In-app chat'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isSafety) ...[
                    const SectionLabel('Severity'),
                    SegmentedTabs(
                      labels: const ['Low', 'Medium', 'High'],
                      selected: _severity,
                      onChanged: (i) => setState(() => _severity = i),
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    label: isSafety
                        ? 'Tell us what happened *'
                        : 'Tell us what happened',
                    hint: 'The more detail you give, the faster we can help',
                    controller: _desc,
                    maxLines: 5,
                    maxLength: 1000,
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
                                width: 64,
                                height: 64,
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
                      if (_photos < 4)
                        Flexible(
                          child: GestureDetector(
                            onTap: () => setState(() => _photos++),
                            child: Container(
                              height: 64,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(
                                  color: context.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: context.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Add photos or screenshots',
                                      style: theme.textTheme.labelMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isCharge || isLost || cat.contains('refund')) ...[
                    const SizedBox(height: 16),
                    const SectionLabel('Preferred resolution'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in [
                          'Refund',
                          'Credit to wallet',
                          'Just want to understand',
                          'Other',
                        ])
                          SelectChip(
                            label: r,
                            selected: (draft.resolution ?? 'Refund') == r,
                            onTap: () => ref
                                .read(caseDraftProvider.notifier)
                                .setResolution(r),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Submit',
                    onPressed: canSubmit
                        ? () => context.go(Routes.caseSubmitted)
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

class _Naira extends StatelessWidget {
  const _Naira();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 14, right: 6),
    child: Text(
      '₦',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}

/// 11.4 — Case submitted.
class CaseSubmittedScreen extends ConsumerWidget {
  const CaseSubmittedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const ref_ = 'NM-2026-00847';
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
                "We've received your report",
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Our team is on it.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Case reference',
                            style: theme.textTheme.labelMedium,
                          ),
                          Text(ref_, style: AppText.mono(context, size: 24)),
                        ],
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.copy_rounded,
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: ref_));
                        showToast(
                          context,
                          'Reference copied',
                          kind: ToastKind.success,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                color: context.tint,
                borderColor: Colors.transparent,
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "We'll respond within 2 hours for payment issues · 15 min for safety concerns",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Track this case',
                onPressed: () => context.go(Routes.caseDetail(ref_)),
              ),
              GhostButton(
                label: 'Go Home',
                onPressed: () => context.go(Routes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 11.5 — My cases.
class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key});
  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = Mock.cases;
    final open = all
        .where(
          (c) =>
              c.status != CaseStatus.resolved && c.status != CaseStatus.closed,
        )
        .toList();
    final resolved = all
        .where(
          (c) =>
              c.status == CaseStatus.resolved || c.status == CaseStatus.closed,
        )
        .toList();
    final sections = switch (_tab) {
      1 => {'Open': open},
      2 => {'Resolved': resolved},
      _ => {'Open': open, 'Resolved': resolved},
    };
    return Scaffold(
      appBar: AppBar(title: const Text('My Cases')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.issueCategory),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        tooltip: 'New Case',
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          FilterTabs(
            labels: const ['All', 'Open', 'Resolved'],
            counts: [all.length, open.length, resolved.length],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const Divider(),
          Expanded(
            child: all.isEmpty
                ? const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No support cases yet',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final e in sections.entries)
                        if (e.value.isNotEmpty) ...[
                          SectionLabel(e.key),
                          for (final c in e.value) ...[
                            AppCard(
                              padding: const EdgeInsets.all(14),
                              onTap: () =>
                                  context.push(Routes.caseDetail(c.reference)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        c.reference,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontFeatures: AppText.tabular,
                                            ),
                                      ),
                                      const Spacer(),
                                      caseBadge(c.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        c.icon,
                                        size: 20,
                                        color: AppColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          c.title,
                                          style: theme.textTheme.titleSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    c.preview,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        relative(c.updated),
                                        style: theme.textTheme.labelSmall,
                                      ),
                                      const Spacer(),
                                      if (c.unread)
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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

/// 11.6 — Case detail & chat thread.
class CaseChatScreen extends StatefulWidget {
  const CaseChatScreen({super.key, required this.reference});
  final String reference;
  @override
  State<CaseChatScreen> createState() => _CaseChatScreenState();
}

class _CaseChatScreenState extends State<CaseChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final _messages = [...Mock.caseThread];
  bool _summaryOpen = false;
  bool _typing = true;
  bool _resolvedBanner = false;

  SupportCase get _case => Mock.cases.firstWhere(
    (c) => c.reference == widget.reference,
    orElse: () => Mock.cases.first,
  );

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final t = (text ?? _input.text).trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          sender: MessageSender.rider,
          text: t,
          time: DateTime(2026, 9, 11, 17, 42),
          read: false,
        ),
      );
      _input.clear();
      _typing = true;
    });
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(
          ChatMessage(
            sender: MessageSender.agent,
            text:
                "Thanks — I've refunded the ₦ 150 surge difference to your NaijaMove Wallet. Marking this as resolved.",
            time: DateTime(2026, 9, 11, 17, 43),
          ),
        );
        _messages.add(
          ChatMessage(
            sender: MessageSender.system,
            text: 'Status changed to Resolved',
            time: DateTime(2026, 9, 11, 17, 43),
          ),
        );
        _resolvedBanner = true;
      });
      _jump();
    });
    _jump();
  }

  void _jump() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _case;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.reference,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFeatures: AppText.tabular,
              ),
            ),
            Text(
              c.title,
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: _resolvedBanner
                  ? caseBadge(CaseStatus.resolved)
                  : caseBadge(c.status),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'close') context.push(Routes.caseResolved);
              if (v == 'trip' && c.trip != null) {
                context.push(Routes.receipt(c.trip!.id));
              }
              if (v == 'escalate') {
                showToast(context, 'Case escalated to a senior agent');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'close', child: Text('Close Case')),
              PopupMenuItem(value: 'escalate', child: Text('Escalate')),
              PopupMenuItem(value: 'trip', child: Text('View Trip')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible summary
          InkWell(
            onTap: () => setState(() => _summaryOpen = !_summaryOpen),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.surface,
                border: Border(bottom: BorderSide(color: context.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${c.trip != null ? 'Trip ${c.trip!.pickup.address.split(',').first} → ${c.trip!.destination.name} · ' : ''}Submitted ${dayMonthTime(DateTime(2026, 9, 11, 15, 50))} · 1 attachment',
                          style: theme.textTheme.bodySmall,
                          maxLines: _summaryOpen ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _summaryOpen
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: context.textSecondary,
                      ),
                    ],
                  ),
                  if (_summaryOpen) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"I was quoted ₦ 1,200 but charged ₦ 1,350." — Preferred resolution: Refund',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              children: [
                for (var i = 0; i < _messages.length; i++)
                  ChatBubble(
                    message: _messages[i],
                    showAvatar:
                        _messages[i].sender == MessageSender.agent &&
                        (i == 0 ||
                            _messages[i - 1].sender != MessageSender.agent),
                    senderName: 'NaijaMove Support',
                  ),
                if (_typing) const TypingIndicator(),
                if (_resolvedBanner)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successTeal,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your issue has been resolved. Was this helpful?',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ThumbButton(
                              icon: Icons.thumb_up_rounded,
                              label: 'Yes',
                              onTap: () => context.push(Routes.caseResolved),
                            ),
                            const SizedBox(width: 10),
                            _ThumbButton(
                              icon: Icons.thumb_down_rounded,
                              label: 'No',
                              onTap: () =>
                                  setState(() => _resolvedBanner = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinkText(
                          'Reopen Case',
                          color: Colors.white,
                          size: 13,
                          onTap: () => setState(() => _resolvedBanner = false),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!_resolvedBanner) ...[
            QuickReplies(
              options: const [
                "Yes, that's correct",
                'No, still an issue',
                'Thank you',
              ],
              onPick: _send,
              filled: true,
            ),
            const SizedBox(height: 8),
          ],
          ChatInputBar(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

class _ThumbButton extends StatelessWidget {
  const _ThumbButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        shape: const StadiumBorder(),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

/// 11.7 — Case resolved / CSAT.
class CaseResolvedScreen extends StatefulWidget {
  const CaseResolvedScreen({super.key});
  @override
  State<CaseResolvedScreen> createState() => _CaseResolvedScreenState();
}

class _CaseResolvedScreenState extends State<CaseResolvedScreen> {
  int _stars = 5;
  final _tags = <String>{'Fast response', 'Helpful agent'};
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SuccessCheck(size: 80),
              const SizedBox(height: 16),
              Text('Case Resolved', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NM-2026-00847 · Incorrect charge',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Resolution: ₦ 150 difference refunded to your NaijaMove Wallet',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'How satisfied are you with our support?',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              StarRating(
                value: _stars,
                size: 44,
                onChanged: (v) => setState(() => _stars = v),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in [
                    'Fast response',
                    'Helpful agent',
                    'Issue fixed',
                    'Clear explanation',
                  ])
                    SelectChip(
                      label: t,
                      selected: _tags.contains(t),
                      onTap: () => setState(
                        () =>
                            _tags.contains(t) ? _tags.remove(t) : _tags.add(t),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Submit Feedback',
                onPressed: () {
                  showToast(
                    context,
                    'Thanks for your feedback',
                    kind: ToastKind.success,
                  );
                  context.go(Routes.home);
                },
              ),
              const SizedBox(height: 8),
              LinkText(
                'Reopen Case',
                color: context.textSecondary,
                onTap: () => context.pop(),
              ),
              Text('Available for 7 days', style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// 11.8 — In-trip driver chat.
class DriverChatScreen extends ConsumerStatefulWidget {
  const DriverChatScreen({super.key});
  @override
  ConsumerState<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends ConsumerState<DriverChatScreen> {
  final _input = TextEditingController();
  late final _messages = [...Mock.driverThread];
  bool _bannerVisible = true;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final t = (text ?? _input.text).trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          sender: MessageSender.rider,
          text: t,
          time: DateTime(2026, 9, 11, 15, 33),
        ),
      );
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider);
    final driver = trip.driver ?? Mock.driver;
    final ended =
        trip.status == TripStatus.completed ||
        trip.status == TripStatus.cancelled;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(name: driver.name, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${driver.vehicle.description} · ${driver.vehicle.plate}',
                    style: theme.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!ended)
              const StatusBadge('Active Trip', kind: BadgeKind.inProgress),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => showToast(context, 'Calling driver…'),
            icon: const Icon(Icons.call_rounded, color: AppColors.primaryBlue),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_bannerVisible && !ended)
            Container(
              color: context.tint,
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chats are monitored for safety. Do not share personal details.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _bannerVisible = false),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              children: [
                Center(
                  child: Text(
                    dayLabel(DateTime(2026, 9, 11)),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                for (var i = 0; i < _messages.length; i++)
                  ChatBubble(
                    message: _messages[i],
                    showAvatar:
                        _messages[i].sender == MessageSender.driver &&
                        (i == 0 ||
                            _messages[i - 1].sender != MessageSender.driver),
                    avatarName: driver.name,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ended
                            ? 'This trip has ended. Chat is now closed.'
                            : 'Chat ends when trip is completed',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!ended) ...[
            QuickReplies(options: Mock.driverQuickReplies, onPick: _send),
            const SizedBox(height: 8),
          ],
          ChatInputBar(
            controller: _input,
            onSend: _send,
            hint: 'Message ${driver.firstName}…',
            allowAttachments: false,
            enabled: !ended,
          ),
        ],
      ),
    );
  }
}

/// 11.9 — FAQ article.
class FaqArticleScreen extends StatefulWidget {
  const FaqArticleScreen({super.key});
  @override
  State<FaqArticleScreen> createState() => _FaqArticleScreenState();
}

class _FaqArticleScreenState extends State<FaqArticleScreen> {
  bool? _helpful;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const a = Mock.refundArticle;
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(a.breadcrumb.join(' › '), style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
          Text(a.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 14),
          Text(a.intro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          for (final (i, s) in a.steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.tint,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(s, style: theme.textTheme.bodyLarge),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            a.highlight,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.tint,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: const Border(
                left: BorderSide(color: AppColors.primaryBlue, width: 4),
              ),
            ),
            child: Text('Tip: ${a.tip}', style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text('Was this helpful?', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              SelectChip(
                label: 'Yes',
                icon: Icons.thumb_up_outlined,
                selected: _helpful == true,
                onTap: () => setState(() => _helpful = true),
              ),
              const SizedBox(width: 8),
              SelectChip(
                label: 'No',
                icon: Icons.thumb_down_outlined,
                selected: _helpful == false,
                onTap: () => setState(() => _helpful = false),
              ),
            ],
          ),
          if (_helpful == false) ...[
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Contact Support',
              onPressed: () => context.push(Routes.issueCategory),
            ),
          ],
          const SizedBox(height: 24),
          const SectionLabel('Related articles'),
          for (final r in a.related)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                r,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: context.textSecondary,
              ),
              onTap: () {},
            ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: 'Still need help? Chat with us',
            icon: Icons.chat_bubble_rounded,
            onPressed: () => context.push(Routes.caseDetail('NM-2026-00847')),
          ),
        ),
      ),
    );
  }
}
