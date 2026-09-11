import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../data/mock_data.dart';
import '../../data/repositories/auth_repository.dart';

/// Small eyebrow chip above auth headings ("LAGOS RIDER VERIFICATION").
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label, {required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared auth page chrome: brand bar, eyebrow, heading, sub-copy, keyboard-aware footer.
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    this.eyebrow,
    this.showBack = true,
    this.trailing,
  });
  final String title;
  final Widget subtitle;
  final Widget child;
  final Widget footer;
  final Widget? eyebrow;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: showBack ? const BackButton() : null,
        title: const BrandLockup(size: 22),
        actions: [?trailing, const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[eyebrow!, const SizedBox(height: 12)],
              Text(title, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              subtitle,
              const SizedBox(height: 24),
              Expanded(child: SingleChildScrollView(child: child)),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// 1.3 — Phone number entry.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});
  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  /// Mock: the sample rider's number is "already registered".
  bool get _returning => _ctrl.text.replaceAll(' ', '') == '8031234567';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).requestOtp('+234${_ctrl.text.replaceAll(' ', '')}');
    } catch (_) {
      // Best-effort — proceed to OTP screen regardless so UX is not blocked.
    }
    if (!mounted) return;
    setState(() => _sending = false);
    context.push(Routes.otp, extra: (returning: _returning, phone: _ctrl.text.replaceAll(' ', '')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = _ctrl.text.replaceAll(' ', '').length == 10;
    return _AuthScaffold(
      title: 'Enter your phone number',
      showBack: false,
      eyebrow: const _Eyebrow(
        'Lagos rider verification',
        icon: Icons.verified_user_outlined,
      ),
      subtitle: Text(
        _returning
            ? "Welcome back! We'll send you a code to log in."
            : "We'll send you a 6-digit code to securely confirm your account.",
        style: theme.textTheme.bodyLarge?.copyWith(
          color: context.textSecondary,
        ),
      ),
      footer: Column(
        children: [
          PrimaryButton(
            label: 'Send Verification Code',
            icon: Icons.arrow_forward_rounded,
            onPressed: valid ? _send : null,
            loading: _sending,
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              text: 'By continuing you agree to our ',
              style: theme.textTheme.bodySmall,
              children: const [
                TextSpan(
                  text: 'Terms',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: '. Standard network SMS rates may apply.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Mobile number'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.bg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: context.border),
                      ),
                      child: Row(
                        children: [
                          const _NigeriaFlag(),
                          const SizedBox(width: 8),
                          Text(
                            '+234',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppTextField(
                        controller: _ctrl,
                        hint: '803 456 7890',
                        autofocus: true,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                          _PhoneFormatter(),
                        ],
                        onChanged: (_) => setState(() {}),
                        suffix: _ctrl.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () => setState(_ctrl.clear),
                                icon: Icon(
                                  Icons.cancel_rounded,
                                  color: context.textSecondary,
                                  size: 20,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Secured via SMS & WhatsApp backup',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.tint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.successTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MTN / Airtel / Glo',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Changed your SIM recently?',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              LinkText(
                'Find Account',
                size: 13,
                onTap: () => showToast(context, 'Account recovery opens here'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _NigeriaFlag extends StatelessWidget {
  const _NigeriaFlag();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 24,
        height: 16,
        child: Row(
          children: [
            Expanded(child: Container(color: AppColors.nigeriaGreen)),
            Expanded(child: Container(color: Colors.white)),
            Expanded(child: Container(color: AppColors.nigeriaGreen)),
          ],
        ),
      ),
    );
  }
}

/// 1.4 — OTP verification.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.returningUser = false, this.phone = ''});
  final bool returningUser;
  final String phone;
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late final String _phone = widget.phone.isEmpty ? Mock.riderPhone : '+234${widget.phone}';
  int _seconds = 45;
  Timer? _timer;
  bool _error = false;
  bool _verifying = false;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    _code = code;
    setState(() {
      _verifying = true;
      _error = false;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.verifyOtp(_phone, code);
      if (!mounted) return;
      await ref.read(sessionProvider.notifier).loginWithTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        userId: result.result.userId,
      );
      if (result.result.isNewUser) {
        context.go(Routes.profileSetup);
      } else {
        context.go(Routes.home);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _verifying = false;
        _code = '';
      });
      if (!e.message.toLowerCase().contains('otp') && !e.message.toLowerCase().contains('code')) {
        showToast(context, e.message, kind: ToastKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mm = (_seconds ~/ 60).toString();
    final ss = (_seconds % 60).toString().padLeft(2, '0');
    return _AuthScaffold(
      title: 'Enter the code',
      eyebrow: const _Eyebrow('Secure auth', icon: Icons.shield_outlined),
      trailing: const SizedBox(
        width: 110,
        child: Center(child: StepProgress(step: 2, total: 3)),
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              'Sent to ${maskPhone(Mock.riderPhone)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: context.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          LinkText('Edit', size: 14, onTap: () => context.pop()),
        ],
      ),
      footer: PrimaryButton(
        label: 'Verify & Continue',
        icon: Icons.arrow_forward_rounded,
        loading: _verifying,
        onPressed: _code.length == 6 ? () => _verify(_code) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color: context.tint,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.sms_outlined, color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instant SMS dispatch',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        'Fast delivery via MTN / Airtel Lagos gateway',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.signal_cellular_alt_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OtpInput(
            error: _error,
            onCompleted: (code) {
              setState(() => _code = code);
              _verify(code);
            },
          ),
          const SizedBox(height: 12),
          if (_error)
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.dangerRed,
                ),
                const SizedBox(width: 6),
                Text(
                  'Incorrect code. Try again.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.dangerRed,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                if (_seconds > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Resend code in $mm:$ss',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.textSecondary,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ],
                  )
                else
                  LinkText('Resend Code', onTap: _startTimer),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('or', style: theme.textTheme.labelSmall),
                    const SizedBox(width: 8),
                    SelectChip(
                      label: 'Send via WhatsApp',
                      icon: Icons.chat_rounded,
                      selected: true,
                      onTap: () => showToast(
                        context,
                        'Code sent on WhatsApp',
                        kind: ToastKind.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 1.5 — Profile setup (first-time only).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _name.text.trim().isEmpty ? '?' : _name.text.trim();
    return _AuthScaffold(
      title: 'What should we call you?',
      showBack: false,
      eyebrow: const _Eyebrow(
        'Almost there',
        icon: Icons.person_outline_rounded,
      ),
      trailing: const SizedBox(
        width: 110,
        child: Center(child: StepProgress(step: 3, total: 3)),
      ),
      subtitle: Text(
        'This is how drivers will greet you',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: context.textSecondary,
        ),
      ),
      footer: Column(
        children: [
          PrimaryButton(
            label: 'Continue',
            onPressed: _name.text.trim().length >= 2
                ? () => context.go(Routes.home)
                : null,
          ),
          const SizedBox(height: 4),
          GhostButton(
            label: 'Skip for now',
            onPressed: () => context.go(Routes.home),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                Avatar(
                  name: name,
                  size: 96,
                  showEdit: true,
                  onEdit: () => showToast(context, 'Photo picker opens here'),
                ),
                const SizedBox(height: 10),
                LinkText('Add photo (optional)', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Full name',
            hint: 'e.g. Tunde Adeyemi',
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Email (optional)',
            hint: 'For receipts',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
