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

/// 6.1 — Profile home (Profile tab).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Avatar(
                  name: Mock.riderName,
                  size: 96,
                  showEdit: true,
                  onEdit: () => showToast(context, 'Photo picker opens here'),
                ),
                const SizedBox(height: 12),
                Text(Mock.riderName, style: theme.textTheme.headlineSmall),
                Text(Mock.riderPhone, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => context.push(Routes.myRating),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.tint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.accentGold,
                        ),
                        Text(
                          ' ${Mock.riderRating} · ${Mock.riderTrips} trips',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Group('Account', [
            _Item(
              Icons.place_outlined,
              'Saved Places',
              () => context.push(Routes.savedPlaces),
              subtitle: 'Home · Work · ${Mock.savedPlaces.length} more',
            ),
            _Item(
              Icons.group_outlined,
              'Emergency Contacts',
              () => context.push(Routes.emergencyContacts),
              subtitle: 'Trusted contacts notified on trips',
              trailing: StatusBadge(
                '${Mock.emergencyContacts.length} active',
                kind: BadgeKind.info,
              ),
            ),
            _Item(
              Icons.credit_card_rounded,
              'Payment Methods',
              () => context.go(Routes.wallet),
              subtitle: 'Visa ••4242 · GTBank · Cash',
            ),
          ]),
          _Group('Rewards', [
            _Item(
              Icons.card_giftcard_rounded,
              'Promotions & Referrals',
              () => context.push(Routes.promotions),
              subtitle: 'Invite friends, earn ₦ 500 each',
              trailing: const StatusBadge('₦ 500 bonus', kind: BadgeKind.surge),
            ),
            _Item(
              Icons.star_outline_rounded,
              'My Rating',
              () => context.push(Routes.myRating),
              subtitle: '⭐ ${Mock.riderRating} from ${Mock.riderTrips} trips',
            ),
          ]),
          _Group('Safety & Support', [
            _Item(
              Icons.shield_outlined,
              'Safety Settings',
              () => showToast(context, 'Safety settings open here'),
              subtitle: 'PIN verification, audio recording, trip sharing',
            ),
            _Item(
              Icons.help_outline_rounded,
              'Help & Support',
              () => context.push(Routes.support),
              subtitle: 'Trip issues, 24/7 support chat, FAQs',
              trailing: Mock.cases.any((c) => c.unread)
                  ? const StatusBadge('1 open case', kind: BadgeKind.open)
                  : null,
            ),
          ]),
          _Group('App', [
            _Item(
              Icons.notifications_outlined,
              'Notifications',
              () => context.push(Routes.notifications),
              subtitle: 'Push alerts, live trip status, news',
            ),
            _Item(
              session.themeMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              'Appearance',
              () => _themeSheet(context, ref),
              trailing: Text(switch (session.themeMode) {
                ThemeMode.dark => 'Dark',
                ThemeMode.light => 'Light',
                _ => 'System',
              }, style: theme.textTheme.labelMedium),
            ),
            _Item(
              Icons.wifi_off_rounded,
              'Simulate offline',
              () => ref.read(sessionProvider.notifier).toggleOffline(),
              trailing: Switch(
                value: session.offline,
                onChanged: (_) =>
                    ref.read(sessionProvider.notifier).toggleOffline(),
              ),
            ),
          ]),
          SecondaryButton(
            label: 'Log Out',
            icon: Icons.logout_rounded,
            color: AppColors.dangerRed,
            onPressed: () {
              ref.read(sessionProvider.notifier).logout();
              context.go(Routes.phone);
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'NaijaMove Rider v0.1.0 · Lagos',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  void _themeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (m, label, icon) in [
                (
                  ThemeMode.system,
                  'System default',
                  Icons.phone_iphone_rounded,
                ),
                (ThemeMode.light, 'Light', Icons.light_mode_outlined),
                (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
              ])
                IconRow(
                  icon: icon,
                  title: label,
                  onTap: () {
                    ref.read(sessionProvider.notifier).setTheme(m);
                    Navigator.pop(ctx);
                  },
                  trailing: ref.read(sessionProvider).themeMode == m
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
}

class _Item {
  const _Item(
    this.icon,
    this.label,
    this.onTap, {
    this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? trailing;
}

class _Group extends StatelessWidget {
  const _Group(this.title, this.items);
  final String title;
  final List<_Item> items;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (final (i, it) in items.indexed) ...[
                  IconRow(
                    icon: it.icon,
                    title: it.label,
                    subtitle: it.subtitle,
                    onTap: it.onTap,
                    trailing: it.trailing == null
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              it.trailing!,
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: context.textSecondary,
                              ),
                            ],
                          ),
                    dense: true,
                  ),
                  if (i < items.length - 1) const Divider(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 6.2 — Saved places.
class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Places')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                IconRow(
                  icon: Icons.home_rounded,
                  title: 'Home',
                  subtitle: Mock.home.address,
                  onTap: () {},
                  trailing: Icon(
                    Icons.edit_outlined,
                    color: context.textSecondary,
                    size: 20,
                  ),
                ),
                const Divider(),
                IconRow(
                  icon: Icons.work_rounded,
                  title: 'Work',
                  subtitle: Mock.work.address,
                  onTap: () {},
                  trailing: Icon(
                    Icons.edit_outlined,
                    color: context.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Other places'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (final (i, p) in Mock.savedPlaces.indexed) ...[
                  IconRow(
                    icon: Icons.star_rounded,
                    iconColor: AppColors.accentGold,
                    title: p.name,
                    subtitle: p.address,
                    trailing: IconButton(
                      onPressed: () => showToast(context, '${p.name} removed'),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: context.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  if (i < Mock.savedPlaces.length - 1) const Divider(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Add New Place',
            icon: Icons.add_location_alt_outlined,
            onPressed: () => context.push(Routes.search),
          ),
        ],
      ),
    );
  }
}

/// 6.3 — Emergency contacts.
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});
  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late final _contacts = [...Mock.emergencyContacts];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'These contacts can be notified during your trips',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          for (final (i, c) in _contacts.indexed) ...[
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Avatar(name: c.name, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: theme.textTheme.titleSmall),
                        Text(c.phone, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Shares trips',
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 24,
                              child: Switch(
                                value: c.sharesTrips,
                                onChanged: (v) => setState(
                                  () => _contacts[i] = EmergencyContact(
                                    name: c.name,
                                    phone: c.phone,
                                    sharesTrips: v,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _contacts.removeAt(i)),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SecondaryButton(
            label: 'Add Contact',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: _contacts.length >= 3
                ? null
                : () => setState(
                    () => _contacts.add(
                      const EmergencyContact(
                        name: 'Ngozi Bello',
                        phone: '+234 810 222 7781',
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'You can add up to 3 contacts',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// 6.4 — Promotions & referrals.
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});
  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _code = TextEditingController();
  bool _pastOpen = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = Mock.promos.where((p) => p.active).toList();
    final past = Mock.promos.where((p) => !p.active).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Promotions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('Active promos'),
          for (final p in active) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.code,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryDark,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Expires ${dayMonth(p.expires)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.local_offer_rounded,
                    color: AppColors.primaryDark,
                    size: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          const SectionLabel('Referrals'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite friends, earn ₦ 500 each',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'They get ₦ 300 off their first ride. You get ₦ 500 when they complete it.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      const ClipboardData(text: Mock.referralCode),
                    );
                    showToast(
                      context,
                      'Referral code copied',
                      kind: ToastKind.success,
                    );
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: context.bg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: context.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            Mock.referralCode,
                            style: AppText.mono(
                              context,
                              size: 22,
                            ).copyWith(letterSpacing: 3),
                          ),
                        ),
                        const Icon(
                          Icons.copy_rounded,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'WhatsApp',
                        icon: Icons.chat_rounded,
                        color: AppColors.whatsappGreen,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SecondaryButton(
                        label: 'Copy Link',
                        icon: Icons.link_rounded,
                        onPressed: () => showToast(
                          context,
                          'Link copied',
                          kind: ToastKind.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Have a code?'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _code,
                  hint: 'Enter promo code',
                  inputFormatters: [UpperCaseTextFormatter()],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 96,
                child: PrimaryButton(
                  label: 'Apply',
                  onPressed: () {
                    if (_code.text.isEmpty) return;
                    showToast(
                      context,
                      'Promo ${_code.text} applied',
                      kind: ToastKind.success,
                    );
                    _code.clear();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => setState(() => _pastOpen = !_pastOpen),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Past promos (${past.length})',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Icon(
                  _pastOpen
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: context.textSecondary,
                ),
              ],
            ),
          ),
          if (_pastOpen)
            for (final p in past)
              IconRow(
                icon: Icons.local_offer_outlined,
                iconColor: context.textSecondary,
                iconBg: context.bg,
                title: p.code,
                subtitle: '${p.description} · expired ${dayMonth(p.expires)}',
              ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// 7.1 — Notifications centre.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _tab = 0;
  late var _items = [...Mock.notifications];
  static const _tabs = ['All', 'Trips', 'Payments', 'Promotions'];

  List<AppNotification> get _filtered => switch (_tab) {
    1 => _items.where((n) => n.kind == NotificationKind.trip).toList(),
    2 => _items.where((n) => n.kind == NotificationKind.payment).toList(),
    3 => _items.where((n) => n.kind == NotificationKind.promo).toList(),
    _ => _items,
  };

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final groups = <String, List<AppNotification>>{};
    for (final n in items) {
      groups.putIfAbsent(dayLabel(n.time), () => []).add(n);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => setState(
              () => _items = _items
                  .map(
                    (n) => AppNotification(
                      title: n.title,
                      body: n.body,
                      time: n.time,
                      kind: n.kind,
                    ),
                  )
                  .toList(),
            ),
            child: const Text('Mark all read'),
          ),
        ],
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
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: "You're all caught up",
                    subtitle:
                        'New trip updates, payments and promos will show here.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final entry in groups.entries) ...[
                        SectionLabel(entry.key),
                        AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              for (final (i, n) in entry.value.indexed) ...[
                                IconRow(
                                  icon: switch (n.kind) {
                                    NotificationKind.trip =>
                                      Icons.directions_car_rounded,
                                    NotificationKind.payment =>
                                      Icons.payments_rounded,
                                    NotificationKind.promo =>
                                      Icons.local_offer_rounded,
                                  },
                                  iconColor: n.kind == NotificationKind.promo
                                      ? AppColors.accentGold
                                      : null,
                                  title: n.title,
                                  subtitle: '${n.body}\n${timeOf(n.time)}',
                                  trailing: n.unread
                                      ? Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : const SizedBox(width: 10),
                                ),
                                if (i < entry.value.length - 1) const Divider(),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// 9.1 — WhatsApp booking handoff.
class WhatsAppHandoffScreen extends StatelessWidget {
  const WhatsAppHandoffScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.whatsappGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  size: 56,
                  color: AppColors.whatsappGreen,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Book on WhatsApp',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Book rides, get status updates and receipts directly in WhatsApp — handy when data is tight.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Open WhatsApp',
                icon: Icons.open_in_new_rounded,
                color: AppColors.whatsappGreen,
                onPressed: () => showToast(context, 'Opening WhatsApp…'),
              ),
              GhostButton(
                label: 'Use the App Instead',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
