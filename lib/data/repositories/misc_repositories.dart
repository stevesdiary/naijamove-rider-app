import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../mock_data.dart';
import '../models.dart';
import 'repository_providers.dart';

// ─── Notifications ────────────────────────────────────────────────────────────

class NotificationsRepository {
  const NotificationsRepository(this._api);
  final ApiClient _api;

  /// GET /notifications
  Future<List<AppNotification>> getNotifications({int limit = 30}) async {
    if (ApiConfig.useMock) return Mock.notifications;
    final list = await _api.getList(
      '/notifications',
      query: {'limit': '$limit'},
    );
    return list
        .map(
          (e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// POST /notifications/:id/read
  Future<void> markRead(String id) async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/notifications/$id/read');
  }

  /// POST /notifications/read-all
  Future<void> markAllRead() async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/notifications/read-all');
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
);

final notificationsProvider =
    AsyncNotifierProvider<_NotificationsNotifier, List<AppNotification>>(
      _NotificationsNotifier.new,
    );

class _NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() =>
      ref.watch(notificationsRepositoryProvider).getNotifications();

  Future<void> markAllRead() async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    final current = state.value ?? [];
    state = AsyncData(
      current
          .map(
            (n) => AppNotification(
              title: n.title,
              body: n.body,
              time: n.time,
              kind: n.kind,
              unread: false,
            ),
          )
          .toList(),
    );
  }
}

// ─── Support ──────────────────────────────────────────────────────────────────

class SupportRepository {
  const SupportRepository(this._api);
  final ApiClient _api;

  /// GET /support/cases
  Future<List<SupportCase>> getCases() async {
    if (ApiConfig.useMock) return Mock.cases;
    final list = await _api.getList('/support/cases');
    return list
        .map((e) => SupportCase.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// POST /support/cases
  Future<SupportCase> createCase({
    required String category,
    required String description,
    String? tripId,
    String? resolution,
  }) async {
    if (ApiConfig.useMock) {
      return SupportCase(
        reference: 'NM-2026-00999',
        title: category,
        icon: Icons.chat_bubble_outline_rounded,
        status: CaseStatus.open,
        preview: description,
        updated: DateTime.now(),
      );
    }
    final j = await _api.postJson(
      '/support/cases',
      body: {
        'category': category,
        'subject': category,
        'description': description,
        'tripId': ?tripId,
        'preferredResolution': ?resolution,
      },
    );
    return SupportCase.fromJson(j);
  }

  /// GET /support/cases/:id/messages
  Future<List<ChatMessage>> getCaseMessages(String caseId) async {
    if (ApiConfig.useMock) return Mock.caseThread;
    final list = await _api.getList('/support/cases/$caseId/messages');
    return list
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// POST /support/cases/:id/messages
  Future<ChatMessage> sendMessage(String caseId, String body) async {
    if (ApiConfig.useMock) {
      return ChatMessage(
        sender: MessageSender.rider,
        text: body,
        time: DateTime.now(),
      );
    }
    final j = await _api.postJson(
      '/support/cases/$caseId/messages',
      body: {'body': body},
    );
    return ChatMessage.fromJson(j);
  }
}

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(ref.watch(apiClientProvider)),
);

final supportCasesProvider =
    AsyncNotifierProvider<_SupportCasesNotifier, List<SupportCase>>(
      _SupportCasesNotifier.new,
    );

class _SupportCasesNotifier extends AsyncNotifier<List<SupportCase>> {
  @override
  Future<List<SupportCase>> build() =>
      ref.watch(supportRepositoryProvider).getCases();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(supportRepositoryProvider).getCases(),
    );
  }
}

// ─── Promotions ───────────────────────────────────────────────────────────────

class PromotionsRepository {
  const PromotionsRepository(this._api);
  final ApiClient _api;

  /// GET /promotions/my
  Future<List<Promo>> getMyPromos() async {
    if (ApiConfig.useMock) return Mock.promos;
    final list = await _api.getList('/promotions/my');
    return list
        .map((e) => Promo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// POST /promotions/validate
  Future<Promo> validateCode(String code) async {
    if (ApiConfig.useMock) {
      final found = Mock.promos
          .where((p) => p.code == code.toUpperCase())
          .firstOrNull;
      if (found == null) {
        throw const ApiException(
          'INVALID_CODE',
          'Promo code not found or expired.',
        );
      }
      return found;
    }
    final j = await _api.postJson('/promotions/validate', body: {'code': code});
    return Promo.fromJson(j);
  }
}

final promotionsRepositoryProvider = Provider<PromotionsRepository>(
  (ref) => PromotionsRepository(ref.watch(apiClientProvider)),
);
