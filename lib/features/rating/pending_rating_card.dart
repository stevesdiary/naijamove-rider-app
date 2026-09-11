import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../data/models.dart';

/// 10.4 — Floating reminder shown on the Home map when a trip is unrated.
class PendingRatingCard extends StatelessWidget {
  const PendingRatingCard({
    super.key,
    required this.driver,
    required this.onRate,
    required this.onDismiss,
  });
  final Driver driver;
  final VoidCallback onRate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      shadow: true,
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      onTap: onRate,
      child: Row(
        children: [
          Avatar(name: driver.name, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate your trip with ${driver.firstName}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StarRating(
                      value: 0,
                      size: 20,
                      spacing: 2,
                      onChanged: (_) => onRate(),
                    ),
                    const SizedBox(width: 8),
                    LinkText('Rate Now', onTap: onRate, size: 13),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close_rounded,
              color: context.textSecondary,
              size: 20,
            ),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
