/// Backend wiring. Build with
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000
/// to talk to the server; leave it unset to run against the in-app mock data.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  /// True when no backend is configured — repositories fall back to mocks.
  static bool get useMock => baseUrl.isEmpty;

  /// ws(s):// counterpart of [baseUrl] for the trip channel.
  static String get wsBaseUrl {
    final u = Uri.parse(baseUrl);
    return u.replace(scheme: u.scheme == 'https' ? 'wss' : 'ws').toString();
  }

  /// City key the pricing service is configured for.
  static const city = 'lagos';

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);
}
