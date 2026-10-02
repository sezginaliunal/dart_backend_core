import 'dart:convert';

import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);

int _idSeq = 0;

/// Tüm controller'lar için ortak yardımcılar.
/// Kullanım: class UsersController with ControllerHelpers { ... }
mixin ControllerHelpers {
  // ───────────── Yetki ─────────────

  bool isAdmin(Request request) => request.context['role'] == 'ADMIN';

  String? currentUserId(Request request) =>
      request.context['userId'] as String?;

  // ───────────── Hazır hata cevapları ─────────────

  Response invalidBody() => Result<Never>.failure(
        const ValidationFailure('Geçersiz istek gövdesi'),
      ).toResponse();

  Response forbidden(String message) =>
      Result<Never>.failure(UnauthorizedFailure(message)).toResponse();

  // ───────────── Body okuma / parse ─────────────

  /// Body'yi JSON olarak okur. Hata olursa null döner.
  Future<Object?> readBody(Request request) async {
    try {
      return jsonDecode(await request.readAsString());
    } catch (_) {
      return null;
    }
  }

  /// Body'den tek model üretir. id yoksa otomatik üretir.
  /// Hata olursa null döner.
  T? parseModel<T>(
    Map<String, dynamic> json,
    FromJson<T> fromJson, {
    String? forceId,
  }) {
    try {
      final data = Map<String, dynamic>.from(json);
      data['id'] = forceId ?? data['id'] ?? generateId();
      return fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Body'den model listesi üretir.
  /// Tek bir eleman bile hatalıysa null döner.
  List<T>? parseList<T>(
    Object? body,
    FromJson<T> fromJson, {
    bool requireId = false,
  }) {
    if (body is! List) return null;

    final models = <T>[];
    for (final item in body) {
      if (item is! Map<String, dynamic>) return null;
      if (requireId && item['id'] == null) return null;

      final model = parseModel(item, fromJson);
      if (model == null) return null;
      models.add(model);
    }
    return models;
  }

  /// { "ids": ["1", "2"] } gövdesinden id listesi çıkarır.
  List<String>? parseIds(Object? body) {
    if (body is! Map<String, dynamic>) return null;

    final ids = body['ids'];
    if (ids is! List) return null;

    return ids.map((e) => e.toString()).toList();
  }

  String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString() + (_idSeq++).toString();
}
