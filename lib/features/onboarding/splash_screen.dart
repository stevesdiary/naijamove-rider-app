import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/app_state.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/brand.dart';

/// 1.1 — Splash. Auto-advances after 2s: first install → onboarding, returning → phone entry / home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final s = ref.read(sessionProvider);
      if (s.loggedIn) {
        context.go(Routes.home);
      } else if (s.onboarded) {
        context.go(Routes.phone);
      } else {
        context.go(Routes.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withValues(
                    alpha: 0.10 + 0.12 * _pulse.value,
                  ),
                ),
                child: child,
              ),
              child: const BrandMark(
                size: 84,
                tileColor: AppColors.primaryLight,
                iconColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 24),
            const BrandWordmark(size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              'Built for how Nigeria moves',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const Spacer(flex: 3),
            const _Dots(),
            const SizedBox(height: 12),
            Text(
              'LAGOS, NIGERIA',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = ((_c.value * 3) - i).clamp(0.0, 1.0);
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(
                alpha: 0.35 + 0.65 * (1 - (phase - 0.5).abs() * 2).clamp(0, 1),
              ),
            ),
          );
        }),
      ),
    );
  }
}
