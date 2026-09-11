import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../mock_data.dart';
import '../models.dart';
import 'repository_providers.dart';

class MapsRepository {
  const MapsRepository(this._api);
  final ApiClient _api;

  /// GET /maps/geocode?q=...
  Future<List<Place>> geocode(String query) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return Mock.suggestions
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || p.address.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    final list = await _api.getList('/maps/geocode', query: {'q': query});
    return list.map((e) => Place.fromGeocode(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// POST /maps/route
  Future<RouteInfo> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    if (ApiConfig.useMock) {
      return const RouteInfo(distanceMeters: 18200, durationSeconds: 2520);
    }
    final j = await _api.postJson('/maps/route', body: {
      'from': {'lat': fromLat, 'lng': fromLng},
      'to': {'lat': toLat, 'lng': toLng},
    });
    return RouteInfo.fromJson(j);
  }
}

final mapsRepositoryProvider = Provider<MapsRepository>(
  (ref) => MapsRepository(ref.watch(apiClientProvider)),
);
