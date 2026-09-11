import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models.dart';
import 'repository_providers.dart';

class AuthRepository {
  const AuthRepository(this._api);
  final ApiClient _api;

  /// POST /auth/otp/request
  Future<void> requestOtp(String phone) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return;
    }
    await _api.postJson('/auth/otp/request', body: {'phone': phone}, auth: false);
  }

  /// POST /auth/otp/verify → { accessToken, refreshToken, userId, isNewUser, name }
  Future<({String accessToken, String refreshToken, AuthResult result})> verifyOtp(
    String phone,
    String code,
  ) async {
    if (ApiConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (code == '000000') throw const ApiException('INVALID_OTP', 'Incorrect code. Try again.');
      const isNew = false;
      return (
        accessToken: 'mock_access',
        refreshToken: 'mock_refresh',
        result: AuthResult(userId: 'mock_user', isNewUser: isNew),
      );
    }
    final j = await _api.postJson(
      '/auth/otp/verify',
      body: {'phone': phone, 'code': code},
      auth: false,
    );
    return (
      accessToken: j['accessToken'] as String,
      refreshToken: j['refreshToken'] as String,
      result: AuthResult(
        userId: j['userId'] as String,
        isNewUser: j['isNewUser'] == true,
        name: j['name']?.toString(),
      ),
    );
  }

  /// POST /auth/logout
  Future<void> logout() async {
    if (ApiConfig.useMock) return;
    try {
      await _api.postJson('/auth/logout');
    } catch (_) {
      // Best-effort — clear tokens regardless.
    }
    await _api.tokens.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
