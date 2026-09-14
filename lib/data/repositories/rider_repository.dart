import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../mock_data.dart';
import '../models.dart';
import 'repository_providers.dart';

class RiderRepository {
  const RiderRepository(this._api);
  final ApiClient _api;

  /// GET /riders/me
  Future<RiderProfile> getProfile() async {
    if (ApiConfig.useMock) {
      return const RiderProfile(
        userId: 'mock_user',
        name: Mock.riderName,
        phone: Mock.riderPhone,
        rating: Mock.riderRating,
        totalTrips: Mock.riderTrips,
      );
    }
    final j = await _api.getJson('/riders/me');
    return RiderProfile.fromJson(j);
  }

  /// PATCH /riders/me
  Future<RiderProfile> updateProfile({String? name, String? email, String? preferredPaymentMethod}) async {
    if (ApiConfig.useMock) return getProfile();
    final j = await _api.putJson('/riders/me', body: {
      'name': ?name,
      'email': ?email,
      'preferredPaymentMethod': ?preferredPaymentMethod,
    });
    return RiderProfile.fromJson(j);
  }

  /// GET /riders/me/saved-places
  Future<List<Place>> getSavedPlaces() async {
    if (ApiConfig.useMock) return [Mock.home, Mock.work, ...Mock.savedPlaces];
    final list = await _api.getList('/riders/me/saved-places');
    return list.map((e) => Place.fromSaved(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// POST /riders/me/saved-places
  Future<Place> addSavedPlace({required String label, required String name, required String address, double? lat, double? lng}) async {
    if (ApiConfig.useMock) return Place(name: name, address: address, label: label);
    final j = await _api.postJson('/riders/me/saved-places', body: {
      'label': label,
      'name': name,
      'address': address,
      'lat': ?lat,
      'lng': ?lng,
    });
    return Place.fromSaved(j);
  }

  /// DELETE /riders/me/saved-places/:id
  Future<void> deleteSavedPlace(String id) async {
    if (ApiConfig.useMock) return;
    await _api.delete('/riders/me/saved-places/$id');
  }

  /// GET /riders/me/emergency-contacts
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    if (ApiConfig.useMock) return Mock.emergencyContacts;
    final list = await _api.getList('/riders/me/emergency-contacts');
    return list.map((e) => EmergencyContact.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// POST /riders/me/emergency-contacts
  Future<EmergencyContact> addEmergencyContact({required String name, required String phone, bool shareTrips = true}) async {
    if (ApiConfig.useMock) return EmergencyContact(name: name, phone: phone, sharesTrips: shareTrips);
    final j = await _api.postJson('/riders/me/emergency-contacts', body: {
      'name': name,
      'phone': phone,
      'shareTrips': shareTrips,
    });
    return EmergencyContact.fromJson(j);
  }

  /// DELETE /riders/me/emergency-contacts/:id
  Future<void> deleteEmergencyContact(String id) async {
    if (ApiConfig.useMock) return;
    await _api.delete('/riders/me/emergency-contacts/$id');
  }
}

final riderRepositoryProvider = Provider<RiderRepository>(
  (ref) => RiderRepository(ref.watch(apiClientProvider)),
);

/// Cached rider profile — auto-fetched once per session.
final riderProfileProvider = AsyncNotifierProvider<_RiderProfileNotifier, RiderProfile>(
  _RiderProfileNotifier.new,
);

class _RiderProfileNotifier extends AsyncNotifier<RiderProfile> {
  @override
  Future<RiderProfile> build() => ref.watch(riderRepositoryProvider).getProfile();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(riderRepositoryProvider).getProfile());
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final updated = await ref.read(riderRepositoryProvider).updateProfile(name: name, email: email);
    state = AsyncData(updated);
  }
}
