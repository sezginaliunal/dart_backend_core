import 'dart:convert';

import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';
import 'products_model.dart';
import 'products_service.dart';

class ProductsController {
  final ProductsService _service;

  ProductsController(this._service);

  // ───────────── READ ─────────────

  Future<Response> getById(Request request, String id) async {
    final result = await _service.getById(id);
    return result.toResponse();
  }

  Future<Response> findAll(Request request) async {
    final result = await _service.findAll();
    return result.toResponse();
  }

  // ───────────── CREATE ─────────────

  /// POST /  →  body: { ... }
  Future<Response> create(Request request) async {
    final body = await _readBody(request);
    if (body is! Map<String, dynamic>) return _invalidBody();

    final model = _parseModel(body);
    if (model == null) return _invalidBody();

    final result = await _service.create(model);
    return result.toResponse();
  }

  /// POST /bulk  →  body: [ { ... }, { ... } ]   (sadece ADMIN)
  Future<Response> bulkCreate(Request request) async {
    if (!_isAdmin(request)) {
      return _forbidden('Toplu ekleme sadece ADMIN tarafından yapılabilir.');
    }

    final models = _parseList(await _readBody(request));
    if (models == null) return _invalidBody();

    final result = await _service.bulkCreate(models);
    return result.toResponse();
  }

  // ───────────── UPDATE ─────────────

  /// PUT /<id>  →  body: { ... }   (ADMIN veya kendi kaydı)
  Future<Response> update(Request request, String id) async {
    final currentUserId = request.context['userId'] as String?;

    if (!_isAdmin(request) && currentUserId != id) {
      return _forbidden(
        'Sadece kendi hesabınızı veya ADMIN olarak bu hesabı güncelleyebilirsiniz.',
      );
    }

    final body = await _readBody(request);
    if (body is! Map<String, dynamic>) return _invalidBody();

    // Path'teki id her zaman body'deki id'nin önüne geçer
    final model = _parseModel(body, forceId: id);
    if (model == null) return _invalidBody();

    final result = await _service.update(id, model);
    return result.toResponse();
  }

  /// PUT /bulk  →  body: [ { "id": "1", ... }, { "id": "2", ... } ]   (sadece ADMIN)
  Future<Response> bulkUpdate(Request request) async {
    if (!_isAdmin(request)) {
      return _forbidden('Toplu güncelleme sadece ADMIN tarafından yapılabilir.');
    }

    final models = _parseList(await _readBody(request), requireId: true);
    if (models == null) return _invalidBody();

    final result = await _service.bulkUpdate(models);
    return result.toResponse();
  }

  // ───────────── DELETE ─────────────

  Future<Response> deleteById(Request request, String id) async {
    final currentUserId = request.context['userId'] as String?;

    // Kullanıcı ADMIN değilse VE kendi ID'sini silmeye çalışmıyorsa engelle
    final isSelf = currentUserId == id;

    if (!_isAdmin(request) && !isSelf) {
      return _forbidden(
        'Sadece kendi hesabınızı veya ADMIN olarak bu hesabı silebilirsiniz.',
      );
    }

    final result = await _service.deleteById(id);
    return result.toResponse();
  }

  /// DELETE /bulk  →  body: { "ids": ["1", "2", "3"] }   (sadece ADMIN)
  Future<Response> bulkDelete(Request request) async {
    if (!_isAdmin(request)) {
      return _forbidden('Toplu silme sadece ADMIN tarafından yapılabilir.');
    }

    final body = await _readBody(request);
    if (body is! Map<String, dynamic> || body['ids'] is! List) {
      return _invalidBody();
    }

    final ids = (body['ids'] as List).map((e) => e.toString()).toList();

    final result = await _service.bulkDelete(ids);
    return result.toResponse();
  }

  // ───────────── HELPERS ─────────────

  static int _seq = 0;

  bool _isAdmin(Request request) => request.context['role'] == 'ADMIN';

  Response _invalidBody() => Result<Never>.failure(
        const ValidationFailure('Geçersiz istek gövdesi'),
      ).toResponse();

  Response _forbidden(String message) =>
      Result<Never>.failure(UnauthorizedFailure(message)).toResponse();

  Future<Object?> _readBody(Request request) async {
    try {
      return jsonDecode(await request.readAsString());
    } catch (_) {
      return null;
    }
  }

  /// Body'den model üretir. id yoksa otomatik üretir, hata olursa null döner.
  ProductsModel? _parseModel(Map<String, dynamic> json, {String? forceId}) {
    try {
      final data = Map<String, dynamic>.from(json);
      data['id'] = forceId ?? data['id'] ?? _generateId();
      return ProductsModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Body'den model listesi üretir. Tek bir eleman bile hatalıysa null döner.
  List<ProductsModel>? _parseList(Object? body, {bool requireId = false}) {
    if (body is! List) return null;

    final models = <ProductsModel>[];
    for (final item in body) {
      if (item is! Map<String, dynamic>) return null;
      if (requireId && item['id'] == null) return null;

      final model = _parseModel(item);
      if (model == null) return null;
      models.add(model);
    }
    return models;
  }

  String _generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString() + (_seq++).toString();
}
