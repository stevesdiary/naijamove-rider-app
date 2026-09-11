import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/app_state.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// 2.2 — Destination search overlay.
class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});
  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  final _to = TextEditingController();
  late final _from = TextEditingController(text: Mock.pickup.address);
  bool _addingStop = false;

  @override
  void dispose() {
    _to.dispose();
    _from.dispose();
    super.dispose();
  }

  void _pick(Place p) {
    final draft = ref.read(rideDraftProvider.notifier);
    if (_addingStop) {
      draft.addStop(p);
      setState(() => _addingStop = false);
      return;
    }
    draft.setDestination(p);
    context.push(Routes.rideOptions);
  }

  List<Place> _filter(List<Place> src) {
    final q = _to.text.trim().toLowerCase();
    if (q.isEmpty) return src;
    return src
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.address.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(rideDraftProvider);
    final maxStops = draft.stops.length >= 3;

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.surface,
        title: const Text('Where to?'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.bg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 18),
                      const RouteDot(color: AppColors.primaryBlue),
                      Container(
                        width: 2,
                        height: 34,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: context.border,
                      ),
                      const RouteDot(color: AppColors.dangerRed, square: true),
                      const SizedBox(height: 18),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        _Field(controller: _from, label: 'PICKUP LOCATION'),
                        const SizedBox(height: 8),
                        for (final s in draft.stops) ...[
                          _StopChip(place: s),
                          const SizedBox(height: 8),
                        ],
                        _Field(
                          controller: _to,
                          label: _addingStop ? 'ADD STOP' : 'DESTINATION',
                          autofocus: true,
                          focused: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppIconButton(
                    icon: Icons.swap_vert_rounded,
                    size: 40,
                    onPressed: () {
                      final t = _from.text;
                      _from.text = _to.text;
                      _to.text = t;
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SelectChip(
                    label: 'Home · ${Mock.home.address}',
                    icon: Icons.home_rounded,
                    onTap: () => _pick(Mock.home),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectChip(
                    label: 'Work · ${Mock.work.address}',
                    icon: Icons.work_rounded,
                    onTap: () => _pick(Mock.work),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _Section('Suggestions', _filter(Mock.suggestions), _pick),
                _Section('Recent', _filter(Mock.recents), _pick),
                _Section('Saved places', _filter(Mock.savedPlaces), _pick),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: maxStops
                  ? Text('Max stops reached', style: theme.textTheme.bodySmall)
                  : Center(
                      child: LinkText(
                        _addingStop ? 'Cancel adding stop' : '+ Add stop',
                        onTap: () => setState(() => _addingStop = !_addingStop),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.focused = false,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final bool focused;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: focused ? AppColors.primaryBlue : context.border,
          width: focused ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
          TextField(
            controller: controller,
            autofocus: autofocus,
            onChanged: onChanged,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopChip extends StatelessWidget {
  const _StopChip({required this.place});
  final Place place;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.tint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_location_alt_outlined,
            size: 16,
            color: context.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              place.name,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.places, this.onPick);
  final String title;
  final List<Place> places;
  final ValueChanged<Place> onPick;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SectionLabel(title),
        for (final p in places)
          IconRow(
            icon: p.icon,
            title: p.name,
            subtitle: p.address,
            onTap: () => onPick(p),
            trailing: p.distanceKm == null
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: context.border),
                    ),
                    child: Text(
                      '${p.distanceKm} km',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
