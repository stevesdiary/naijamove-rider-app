/// Central provider file — exposes one ApiClient instance shared by all
/// repositories, and a convenience [ref.api] extension.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

final tokenStoreProvider = Provider<TokenStore>((_) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenStoreProvider);
  return ApiClient(
    tokens,
    onSessionExpired: () {
      // Handled by the session provider — clear state and redirect to /phone.
    },
  );
});
