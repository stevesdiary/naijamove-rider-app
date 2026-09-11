import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/components.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';

/// Bottom-nav shell: Home · Trips · Wallet · Profile.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _items = [
    (Icons.map_outlined, Icons.map_rounded, 'Home'),
    (Icons.schedule_outlined, Icons.schedule_rounded, 'Trips'),
    (
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
      'Wallet',
    ),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(sessionProvider.select((s) => s.offline));
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          if (offline)
            SafeArea(bottom: false, child: OfflineBanner(visible: offline)),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surface,
          border: Border(top: BorderSide(color: context.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_items.length, (i) {
                final (icon, activeIcon, label) = _items[i];
                final active = navigationShell.currentIndex == i;
                return Expanded(
                  child: InkWell(
                    onTap: () =>
                        navigationShell.goBranch(i, initialLocation: active),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 56,
                          height: 30,
                          decoration: BoxDecoration(
                            color: active ? context.tint : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            active ? activeIcon : icon,
                            size: 22,
                            color: active
                                ? AppColors.primaryBlue
                                : context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppColors.primaryBlue
                                : context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
