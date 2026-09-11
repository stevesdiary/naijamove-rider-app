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

/// 4.1 — Wallet & payment methods (Wallet tab landing).
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(sessionProvider.select((s) => s.walletBalance));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Wallet card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NaijaMove Wallet',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const StatusBadge(
                      'Active & ready',
                      kind: BadgeKind.completed,
                      icon: Icons.check_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'AVAILABLE BALANCE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  naira(balance),
                  style: AppText.fare(
                    context,
                    size: 36,
                  ).copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enough for ~${(balance / 1200).floor()} standard Island / Mainland trips',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Top Up',
                        icon: Icons.add_rounded,
                        onPressed: () => context.push(Routes.topUp),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(Routes.transactions),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white54,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          icon: const Icon(
                            Icons.receipt_long_rounded,
                            size: 20,
                          ),
                          label: const Text('Transactions'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Payment methods'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final (i, pm) in Mock.paymentMethods.indexed) ...[
                  IconRow(
                    icon: pm.icon,
                    title: pm.label,
                    subtitle: pm.type == PaymentMethodType.cash
                        ? 'Pay your driver directly'
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pm.isDefault)
                          const StatusBadge('Default', kind: BadgeKind.info),
                        if (pm.type != PaymentMethodType.cash)
                          IconButton(
                            onPressed: () =>
                                showToast(context, '${pm.label} removed'),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: context.textSecondary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (i < Mock.paymentMethods.length - 1) const Divider(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _AutoTopUpRow(),
          const SizedBox(height: 20),
          const SectionLabel('Add new method'),
          SecondaryButton(
            label: 'Add Debit / Credit Card',
            icon: Icons.credit_card_rounded,
            onPressed: () => context.push(Routes.addCard),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Add Bank Account',
            icon: Icons.account_balance_rounded,
            onPressed: () =>
                showToast(context, 'Bank account linking opens here'),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: context.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bank-grade security. NDIC-insured partner banks · CBN-licensed payment processor. '
                  'Your card details are tokenised and never stored on our servers.',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Auto top-up toggle row (reloads the wallet when the balance dips).
class _AutoTopUpRow extends StatefulWidget {
  const _AutoTopUpRow();
  @override
  State<_AutoTopUpRow> createState() => _AutoTopUpRowState();
}

class _AutoTopUpRowState extends State<_AutoTopUpRow> {
  bool _on = false;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: IconRow(
        icon: Icons.autorenew_rounded,
        iconColor: AppColors.successTeal,
        iconBg: AppColors.successTint,
        title: 'Auto top-up wallet',
        subtitle: 'Reload ₦ 2,000 when balance falls below ₦ 500',
        trailing: Switch(value: _on, onChanged: (v) => setState(() => _on = v)),
      ),
    );
  }
}

/// 4.2 — Wallet top up.
class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});
  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  static const _quick = [500, 1000, 2000, 5000];
  int? _amount = 1000;
  bool _custom = false;
  final _customCtrl = TextEditingController();
  PaymentMethod _method = Mock.visa;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = _custom
        ? int.tryParse(_customCtrl.text.replaceAll(RegExp(r'\D'), ''))
        : _amount;
    return Scaffold(
      appBar: AppBar(title: const Text('Top Up Wallet')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Amount'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in _quick)
                    SelectChip(
                      label: naira(v),
                      filled: true,
                      selected: !_custom && _amount == v,
                      onTap: () => setState(() {
                        _custom = false;
                        _amount = v;
                      }),
                    ),
                  SelectChip(
                    label: 'Custom',
                    filled: true,
                    selected: _custom,
                    onTap: () => setState(() => _custom = true),
                  ),
                ],
              ),
              if (_custom) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Custom amount',
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
              const SizedBox(height: 24),
              const SectionLabel('Pay with'),
              for (final pm in Mock.paymentMethods.where(
                (p) => p.type != PaymentMethodType.cash,
              ))
                AppCard(
                  padding: EdgeInsets.zero,
                  borderColor: _method.id == pm.id
                      ? AppColors.primaryBlue
                      : null,
                  color: _method.id == pm.id ? context.tint : null,
                  onTap: () => setState(() => _method = pm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconRow(
                      icon: pm.icon,
                      title: pm.label,
                      trailing: Icon(
                        _method.id == pm.id
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: _method.id == pm.id
                            ? AppColors.primaryBlue
                            : context.border,
                      ),
                    ),
                  ),
                ).withGap(8),
              const Spacer(),
              PrimaryButton(
                label: amount == null || amount <= 0
                    ? 'Top Up'
                    : 'Top Up ${naira(amount)}',
                onPressed: amount == null || amount <= 0
                    ? null
                    : () {
                        ref.read(sessionProvider.notifier).topUp(amount);
                        showToast(
                          context,
                          '${naira(amount)} added to your wallet',
                          kind: ToastKind.success,
                        );
                        context.pop();
                      },
              ),
              const SizedBox(height: 10),
              Center(child: _PaystackBadge(theme: theme)),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Widget {
  Widget withGap(double h) => Padding(
    padding: EdgeInsets.only(bottom: h),
    child: this,
  );
}

class _PaystackBadge extends StatelessWidget {
  const _PaystackBadge({required this.theme});
  final ThemeData theme;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_rounded, size: 14, color: context.textSecondary),
        const SizedBox(width: 6),
        Text('Secured by Paystack', style: theme.textTheme.labelSmall),
      ],
    );
  }
}

/// 4.3 — Transaction history.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _tab = 0;
  static const _tabs = ['All', 'Trips', 'Top-ups', 'Refunds'];

  List<WalletTx> get _filtered => switch (_tab) {
    1 =>
      Mock.transactions
          .where((t) => t.kind == TxKind.trip || t.kind == TxKind.tip)
          .toList(),
    2 => Mock.transactions.where((t) => t.kind == TxKind.topUp).toList(),
    3 => Mock.transactions.where((t) => t.kind == TxKind.refund).toList(),
    _ => Mock.transactions,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;
    final groups = <String, List<WalletTx>>{};
    for (final t in items) {
      groups.putIfAbsent(dayLabel(t.date), () => []).add(t);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          TextButton(
            onPressed: () =>
                showToast(context, 'Statement PDF is being prepared'),
            child: const Text('Download'),
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
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No transactions yet',
                    subtitle:
                        'Top up your wallet or take a ride to see activity here.',
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
                              for (final (i, t) in entry.value.indexed) ...[
                                IconRow(
                                  icon: switch (t.kind) {
                                    TxKind.trip => Icons.directions_car_rounded,
                                    TxKind.tip =>
                                      Icons.volunteer_activism_rounded,
                                    TxKind.topUp => Icons.add_card_rounded,
                                    TxKind.refund =>
                                      Icons.currency_exchange_rounded,
                                  },
                                  title: t.title,
                                  subtitle: timeOf(t.date),
                                  trailing: Text(
                                    naira(t.amount, signed: true),
                                    style:
                                        AppText.fare(
                                          context,
                                          size: 15,
                                          weight: FontWeight.w600,
                                        ).copyWith(
                                          color: t.amount > 0
                                              ? AppColors.successTeal
                                              : AppColors.dangerRed,
                                        ),
                                  ),
                                ),
                                if (i < entry.value.length - 1) const Divider(),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Statements export the currently filtered period as PDF.',
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// 4.4 — Add card (Paystack-style inline form).
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  bool _default = true;

  String get _brand {
    final n = _number.text.replaceAll(' ', '');
    if (n.startsWith('4')) return 'Visa';
    if (n.startsWith('5')) return 'Mastercard';
    if (n.startsWith('506') || n.startsWith('650')) return 'Verve';
    return '';
  }

  bool get _valid =>
      _number.text.replaceAll(' ', '').length == 16 &&
      _expiry.text.length == 5 &&
      _cvv.text.length == 3;

  @override
  void dispose() {
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digits = _number.text.replaceAll(' ', '');
    final last4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : '••••';
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Card')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Card preview
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.accentGold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _brand.isEmpty ? 'CARD' : _brand.toUpperCase(),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '••••  ••••  ••••  $last4',
                          style: AppText.fare(
                            context,
                            size: 20,
                            weight: FontWeight.w600,
                          ).copyWith(color: Colors.white, letterSpacing: 2),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              Mock.riderName.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _expiry.text.isEmpty ? 'MM/YY' : _expiry.text,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'Card number',
                          hint: '0000 0000 0000 0000',
                          controller: _number,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                            _CardNumberFormatter(),
                          ],
                          onChanged: (_) => setState(() {}),
                          suffix: _brand.isEmpty
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Center(
                                    widthFactor: 1,
                                    child: Text(
                                      _brand,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Expiry',
                                hint: 'MM/YY',
                                controller: _expiry,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _ExpiryFormatter(),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'CVV',
                                hint: '•••',
                                controller: _cvv,
                                obscureText: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                onChanged: (_) => setState(() {}),
                                suffix: Tooltip(
                                  message:
                                      'The 3 digits on the back of your card',
                                  triggerMode: TooltipTriggerMode.tap,
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: context.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _default,
                          onChanged: (v) => setState(() => _default = v),
                          title: Text(
                            'Set as default payment method',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your card details are encrypted · Secured by Paystack',
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
                    label: 'Save Card',
                    onPressed: _valid
                        ? () {
                            showToast(
                              context,
                              '$_brand ending in $last4 saved',
                              kind: ToastKind.success,
                            );
                            context.pop();
                          }
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

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
