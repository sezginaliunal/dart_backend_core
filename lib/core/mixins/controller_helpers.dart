import 'dart:convert';

import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);

int _idSeq = 0;

mixin ControllerHelpers {
  // ───────────── Yetki ─────────────

  bool isAdmin(Request request) =>
      request.context[ProjectConstants.contextUserRoleKey] ==
      ProjectConstants.roleAdmin;

  String? currentUserId(Request request) =>
      request.context[ProjectConstants.contextUserIdKey] as String?;

  // ───────────── Hazır hata cevapları ─────────────

  Response invalidBody() => Result<Never>.failure(
    ValidationFailure(ProjectConstants.failures.invalidBody),
  ).toResponse();

  Response forbidden(String message) =>
      Result<Never>.failure(UnauthorizedFailure(message)).toResponse();

  // ───────────── Body okuma / parse ─────────────

  Future<Object?> readBody(Request request) async {
    try {
      return jsonDecode(await request.readAsString());
    } catch (_) {
      return null;
    }
  }

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

  List<String>? parseIds(Object? body) {
    if (body is! Map<String, dynamic>) return null;

    final ids = body['ids'];
    if (ids is! List) return null;

    return ids.map((e) => e.toString()).toList();
  }

  String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString() + (_idSeq++).toString();
}
