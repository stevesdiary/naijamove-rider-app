import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../data/models.dart';

/// Driver card: avatar · name · rating · trips · vehicle · plate · verified tick.
class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.driver,
    this.compact = false,
    this.onTap,
  });
  final Driver driver;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = driver.vehicle;
    return AppCard(
      onTap: onTap ?? () => context.push(Routes.driverProfile(driver.id)),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Row(
        children: [
          Avatar(name: driver.name, size: compact ? 44 : 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        driver.name,
                        style: compact
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppColors.successTeal,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.accentGold,
                    ),
                    Text(
                      ' ${driver.rating}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        ' · ${driver.trips.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')} trips',
                        style: theme.textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(v.description, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          PlateNumber(v.plate, large: !compact),
        ],
      ),
    );
  }
}

/// Plate number rendered large and readable.
class PlateNumber extends StatelessWidget {
  const PlateNumber(this.plate, {super.key, this.large = false});
  final String plate;
  final bool large;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 8,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.border, width: 1.5),
      ),
      child: Text(
        plate,
        style: AppText.fare(
          context,
          size: large ? 16 : 13,
          weight: FontWeight.w700,
        ).copyWith(letterSpacing: 1),
      ),
    );
  }
}

/// Call · Chat · Safety action row.
class TripActionRow extends StatelessWidget {
  const TripActionRow({super.key, this.onCall, this.onChat, this.onSafety});
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onSafety;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AppIconButton(
          icon: Icons.call_rounded,
          label: 'Call',
          onPressed: onCall ?? () => showToast(context, 'Calling driver…'),
        ),
        AppIconButton(
          icon: Icons.chat_bubble_rounded,
          label: 'Chat',
          onPressed: onChat ?? () => context.push(Routes.driverChat),
        ),
        AppIconButton(
          icon: Icons.shield_rounded,
          label: 'Safety',
          onPressed: onSafety ?? () => _safetySheet(context),
        ),
      ],
    );
  }

  static void _safetySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Safety toolkit', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              IconRow(
                icon: Icons.share_location_rounded,
                title: 'Share trip status',
                subtitle: 'Send a live link to a trusted contact',
                onTap: () => Navigator.pop(ctx),
              ),
              IconRow(
                icon: Icons.mic_rounded,
                title: 'Record audio',
                subtitle: 'Encrypted, only shared if you report an issue',
                onTap: () => Navigator.pop(ctx),
              ),
              IconRow(
                icon: Icons.pin_rounded,
                title: 'Verify trip PIN',
                subtitle: 'Confirm you are in the right car',
                onTap: () => Navigator.pop(ctx),
              ),
              IconRow(
                icon: Icons.sos_rounded,
                title: 'Emergency',
                subtitle: 'Call 112 or alert the NaijaMove Safety Team',
                iconColor: AppColors.dangerRed,
                iconBg: AppColors.dangerTint,
                titleColor: AppColors.dangerRed,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(Routes.sos);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trip PIN row with hidden/revealed states.
class TripPinRow extends StatelessWidget {
  const TripPinRow({
    super.key,
    required this.pin,
    required this.revealed,
    required this.onReveal,
  });
  final String pin;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Show PIN to driver', style: theme.textTheme.titleSmall),
                Tooltip(
                  message:
                      "Share this PIN with your driver to confirm it's the right trip",
                  triggerMode: TooltipTriggerMode.tap,
                  child: Row(
                    children: [
                      Text(
                        'What is this?',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: revealed
                ? Text(
                    pin,
                    key: const ValueKey('pin'),
                    style: AppText.mono(context),
                  )
                : Text(
                    '••••',
                    key: const ValueKey('mask'),
                    style: AppText.mono(
                      context,
                    ).copyWith(color: context.textSecondary),
                  ),
          ),
          const SizedBox(width: 12),
          if (!revealed)
            TextButton(onPressed: onReveal, child: const Text('Reveal'))
          else
            Text('hides in 10s', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// Floating SOS button — requires a 2s press-and-hold; shows fill animation.
class SosButton extends StatefulWidget {
  const SosButton({super.key, required this.onTriggered});
  final VoidCallback onTriggered;
  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _c.reset();
          widget.onTriggered();
        }
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      onTap: () => showToast(context, 'Hold for 2 seconds to trigger SOS'),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.dangerRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.dangerRed.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: _c.value,
                  strokeWidth: 4,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
              const Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ETA chip.
class EtaChip extends StatelessWidget {
  const EtaChip(this.label, {super.key, this.color});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
