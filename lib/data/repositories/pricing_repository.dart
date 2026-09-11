import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../mock_data.dart';
import '../models.dart';
import 'repository_providers.dart';

class PricingRepository {
  const PricingRepository(this._api);
  final ApiClient _api;

  /// POST /pricing/quote — returns quotes for all 4 categories.
  Future<List<FareQuote>> getQuotes({
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    String? promoCode,
  }) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return Mock.quotes;
    }
    final results = <FareQuote>[];
    for (final category in VehicleCategory.values) {
      try {
        final j = await _api.postJson('/pricing/quote', body: {
          'pickupLat': pickupLat,
          'pickupLng': pickupLng,
          'destinationLat': destLat,
          'destinationLng': destLng,
          'vehicleCategory': category.wire,
          'city': ApiConfig.city,
          if (promoCode != null) 'promoCode': promoCode,
        });
        results.add(FareQuote.fromJson(j, category));
      } catch (_) {
        // Skip unavailable categories gracefully.
      }
    }
    return results.isEmpty ? Mock.quotes : results;
  }
}

final pricingRepositoryProvider = Provider<PricingRepository>(
  (ref) => PricingRepository(ref.watch(apiClientProvider)),
);
