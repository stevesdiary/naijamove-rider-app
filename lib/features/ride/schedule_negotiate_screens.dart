import 'dart:async';

import 'package:flutter/cupertino.dart';
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
import 'ride_options_screen.dart';

/// 8.1 — Schedule a ride.
class ScheduleRideScreen extends ConsumerStatefulWidget {
  const ScheduleRideScreen({super.key});
  @override
  ConsumerState<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends ConsumerState<ScheduleRideScreen> {
  DateTime _when = DateTime(2026, 9, 14, 5, 30);

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(rideDraftProvider);
    final theme = Theme.of(context);
    final dest = draft.destination ?? Mock.destination;

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule a Ride')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: RouteSummary(
                      pickup: draft.pickup.address,
                      destination: dest.name,
                      dense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Pickup date & time'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 180,
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          brightness: Theme.of(context).brightness,
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle:
                                theme.textTheme.titleMedium,
                          ),
                        ),
                        child: CupertinoDatePicker(
                          initialDateTime: _when,
                          minimumDate: DateTime(2026, 9, 11, 16, 0),
                          maximumDate: DateTime(2026, 10, 11),
                          minuteInterval: 5,
                          onDateTimeChanged: (d) => setState(() => _when = d),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Vehicle'),
                  for (final q in Mock.quotes) ...[
                    VehicleCard(
                      quote: q,
                      selected: q.category == draft.category,
                      onTap: () => ref
                          .read(rideDraftProvider.notifier)
                          .setCategory(q.category),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'Upcoming bookings appear in the Scheduled tab of your Trips.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Schedule Ride · ${dayMonthTime(_when)}',
                onPressed: () {
                  showToast(
                    context,
                    'Ride scheduled for ${dayMonthTime(_when)}',
                    kind: ToastKind.success,
                  );
                  context.go(Routes.trips);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NegotiateState { offer, waiting, counter }

/// 8.2 — Negotiated ride.
class NegotiatedRideScreen extends ConsumerStatefulWidget {
  const NegotiatedRideScreen({super.key});
  @override
  ConsumerState<NegotiatedRideScreen> createState() =>
      _NegotiatedRideScreenState();
}

class _NegotiatedRideScreenState extends ConsumerState<NegotiatedRideScreen> {
  final _offer = TextEditingController(text: '1200');
  _NegotiateState _state = _NegotiateState.offer;
  Timer? _timer;
  static const _floor = 1100;
  static const _counter = 1300;

  @override
  void dispose() {
    _offer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  int get _amount =>
      int.tryParse(_offer.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  void _send() {
    setState(() => _state = _NegotiateState.waiting);
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _state = _NegotiateState.counter);
    });
  }

  void _accept() {
    ref.read(activeTripProvider.notifier).startSearch();
    context.go(Routes.searching);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(rideDraftProvider);
    final theme = Theme.of(context);
    final q = draft.quote;
    final belowFloor = _amount < _floor;

    return Scaffold(
      appBar: AppBar(title: const Text('Negotiate a Fare')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: RouteSummary(
                  pickup: draft.pickup.address,
                  destination: (draft.destination ?? Mock.destination).name,
                  dense: true,
                ),
              ),
              const SizedBox(height: 20),
              Text('Suggested fare', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                nairaRange(q.min, q.max),
                style: AppText.fare(context, size: 28),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 14,
                    color: AppColors.successTeal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Minimum fair fare: ${naira(_floor)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              switch (_state) {
                _NegotiateState.offer => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Your offer',
                      controller: _offer,
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
                      errorText: belowFloor && _amount > 0
                          ? 'Offers below ${naira(_floor)} are not sent to drivers'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final v in [1100, 1200, 1300, 1400])
                          SelectChip(
                            label: naira(v),
                            selected: _amount == v,
                            onTap: () => setState(() => _offer.text = '$v'),
                          ),
                      ],
                    ),
                  ],
                ),
                _NegotiateState.waiting => AppCard(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waiting for a driver to accept…',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              'Your offer: ${naira(_amount)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _NegotiateState.counter => AppCard(
                  borderColor: AppColors.primaryBlue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Avatar(name: Mock.driver.name, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Mock.driver.name,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  '⭐ ${Mock.driver.rating} · ${Mock.vehicle.description}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Counter-offer', style: theme.textTheme.labelMedium),
                      Text(
                        naira(_counter),
                        style: AppText.fare(context, size: 32),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Decline',
                              color: AppColors.dangerRed,
                              onPressed: () => setState(
                                () => _state = _NegotiateState.offer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Accept',
                              onPressed: _accept,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              },
              const Spacer(),
              if (_state == _NegotiateState.offer)
                PrimaryButton(
                  label: 'Send Offer',
                  onPressed: belowFloor ? null : _send,
                )
              else
                GhostButton(label: 'Cancel', onPressed: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }
}
