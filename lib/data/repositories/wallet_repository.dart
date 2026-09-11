import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../mock_data.dart';
import '../models.dart';
import 'repository_providers.dart';

class WalletRepository {
  const WalletRepository(this._api);
  final ApiClient _api;

  /// GET /payments/wallet/balance
  Future<int> getBalance() async {
    if (ApiConfig.useMock) return Mock.walletBalance;
    final j = await _api.getJson('/payments/wallet/balance');
    return (j['balanceKobo'] as num? ?? 0) ~/ 100;
  }

  /// GET /payments/wallet/transactions
  Future<List<WalletTx>> getTransactions({int limit = 50, int offset = 0}) async {
    if (ApiConfig.useMock) return Mock.transactions;
    final list = await _api.getList(
      '/payments/wallet/transactions',
      query: {'limit': '$limit', 'offset': '$offset'},
    );
    return list.map((e) => WalletTx.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// POST /payments/wallet/topup/initialize
  /// Returns Paystack checkout URL + reference. Supports card, bank transfer, USSD.
  Future<TopUpIntent> initializeTopUp({required int amountKobo, required String email}) async {
    if (ApiConfig.useMock) {
      return const TopUpIntent(
        authorizationUrl: 'https://checkout.paystack.com/mock',
        reference: 'mock_ref_topup',
      );
    }
    final j = await _api.postJson('/payments/wallet/topup/initialize', body: {
      'amountKobo': amountKobo,
      'email': email,
    });
    return TopUpIntent.fromJson(j);
  }

  /// GET /riders/me/payment-methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    if (ApiConfig.useMock) return Mock.paymentMethods;
    final list = await _api.getList('/riders/me/payment-methods');
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return PaymentMethod(
        id: '${m['id']}',
        type: PaymentMethodType.fromWire(m['type']?.toString()),
        label: '${m['label'] ?? m['last4'] ?? ''}',
        isDefault: m['isDefault'] == true,
        brand: m['brand']?.toString(),
      );
    }).toList();
  }

  /// DELETE /riders/me/payment-methods/:id
  Future<void> deletePaymentMethod(String id) async {
    if (ApiConfig.useMock) return;
    await _api.delete('/riders/me/payment-methods/$id');
  }
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(apiClientProvider)),
);

/// Live wallet balance — refreshed after top-up confirmation.
final walletBalanceProvider = AsyncNotifierProvider<_WalletBalanceNotifier, int>(
  _WalletBalanceNotifier.new,
);

class _WalletBalanceNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() => ref.watch(walletRepositoryProvider).getBalance();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(walletRepositoryProvider).getBalance());
  }
}

/// Payment methods list.
final paymentMethodsProvider = AsyncNotifierProvider<_PaymentMethodsNotifier, List<PaymentMethod>>(
  _PaymentMethodsNotifier.new,
);

class _PaymentMethodsNotifier extends AsyncNotifier<List<PaymentMethod>> {
  @override
  Future<List<PaymentMethod>> build() => ref.watch(walletRepositoryProvider).getPaymentMethods();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(walletRepositoryProvider).getPaymentMethods());
  }
}
