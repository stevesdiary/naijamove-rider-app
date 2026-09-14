import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../mock_data.dart';
import '../models.dart';
import 'repository_providers.dart';

class RidesRepository {
  const RidesRepository(this._api);
  final ApiClient _api;

  /// POST /rides — create a trip request.
  Future<Trip> requestTrip({
    required Place pickup,
    required Place destination,
    required VehicleCategory category,
    required String paymentMethod,
    List<Place> stops = const [],
    String? quoteId,
    String? promoCode,
    TripMode mode = TripMode.immediate,
    DateTime? scheduledFor,
  }) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return Trip(
        id: 'trp_${DateTime.now().millisecondsSinceEpoch}',
        pickup: pickup,
        destination: destination,
        category: category,
        fare: Mock.fareEstimate,
        date: DateTime.now(),
        status: TripStatus.requested,
        pin: Mock.tripPin,
        mode: mode,
      );
    }
    final j = await _api.postJson('/rides', body: {
      'pickupAddress': pickup.address,
      'pickupLat': pickup.lat,
      'pickupLng': pickup.lng,
      'destinationAddress': destination.address,
      'destinationLat': destination.lat,
      'destinationLng': destination.lng,
      'vehicleCategory': category.wire,
      'paymentMethod': paymentMethod,
      'quoteId': ?quoteId,
      'promoCode': ?promoCode,
      'mode': mode.name,
      'scheduledFor': scheduledFor?.toIso8601String(),
      if (stops.isNotEmpty)
        'stops': stops.map((s) => {'address': s.address, 'lat': s.lat, 'lng': s.lng}).toList(),
    });
    return Trip.fromJson(j);
  }

  /// GET /rides/:id — poll trip status.
  Future<Trip> getTrip(String tripId) async {
    if (ApiConfig.useMock) return Mock.currentTrip;
    final j = await _api.getJson('/rides/$tripId');
    return Trip.fromJson(j);
  }

  /// POST /rides/:id/cancel
  Future<void> cancelTrip(String tripId, {String? reason}) async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/rides/$tripId/cancel', body: {'reason': ?reason});
  }

  /// GET /rides — trip history.
  Future<List<Trip>> getTripHistory({int limit = 20, int offset = 0, String? status}) async {
    if (ApiConfig.useMock) return Mock.trips;
    final list = await _api.getList('/rides', query: {
      'limit': '$limit',
      'offset': '$offset',
      'status': ?status,
    });
    return list.map((e) => Trip.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// POST /rides/:id/rate
  Future<void> rateTrip(String tripId, {required int stars, List<String> tags = const [], String? comment}) async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/rides/$tripId/rate', body: {
      'stars': stars,
      if (tags.isNotEmpty) 'tags': tags,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  /// POST /rides/:id/tip
  Future<void> tipDriver(String tripId, int amountKobo) async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/rides/$tripId/tip', body: {'amountKobo': amountKobo});
  }
}

final ridesRepositoryProvider = Provider<RidesRepository>(
  (ref) => RidesRepository(ref.watch(apiClientProvider)),
);

/// Trip history list provider.
final tripHistoryProvider = AsyncNotifierProvider<_TripHistoryNotifier, List<Trip>>(
  _TripHistoryNotifier.new,
);

class _TripHistoryNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() => ref.watch(ridesRepositoryProvider).getTripHistory();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(ridesRepositoryProvider).getTripHistory());
  }
}
