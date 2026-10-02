import 'package:base_backend/core/mixins/controller_helpers.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';
import 'products_model.dart';
import 'products_service.dart';

class ProductsController with ControllerHelpers {
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
    final body = await readBody(request);
    if (body is! Map<String, dynamic>) return invalidBody();

    final model = parseModel(body, ProductsModel.fromJson);
    if (model == null) return invalidBody();

    final result = await _service.create(model);
    return result.toResponse();
  }

  /// POST /bulk  →  body: [ { ... }, { ... } ]   (sadece ADMIN)
  Future<Response> bulkCreate(Request request) async {
    if (!isAdmin(request)) {
      return forbidden('Toplu ekleme sadece ADMIN tarafından yapılabilir.');
    }

    final models = parseList(await readBody(request), ProductsModel.fromJson);
    if (models == null) return invalidBody();

    final result = await _service.bulkCreate(models);
    return result.toResponse();
  }

  // ───────────── UPDATE ─────────────

  /// PUT /<id>  →  body: { ... }   (ADMIN veya kendi kaydı)
  Future<Response> update(Request request, String id) async {
    if (!isAdmin(request) && currentUserId(request) != id) {
      return forbidden(
        'Sadece kendi hesabınızı veya ADMIN olarak bu hesabı güncelleyebilirsiniz.',
      );
    }

    final body = await readBody(request);
    if (body is! Map<String, dynamic>) return invalidBody();

    // Path'teki id her zaman body'deki id'nin önüne geçer
    final model = parseModel(body, ProductsModel.fromJson, forceId: id);
    if (model == null) return invalidBody();

    final result = await _service.update(id, model);
    return result.toResponse();
  }

  /// PUT /bulk  →  body: [ { "id": "1", ... }, { "id": "2", ... } ]   (sadece ADMIN)
  Future<Response> bulkUpdate(Request request) async {
    if (!isAdmin(request)) {
      return forbidden('Toplu güncelleme sadece ADMIN tarafından yapılabilir.');
    }

    final models = parseList(
      await readBody(request),
      ProductsModel.fromJson,
      requireId: true,
    );
    if (models == null) return invalidBody();

    final result = await _service.bulkUpdate(models);
    return result.toResponse();
  }

  // ───────────── DELETE ─────────────

  /// DELETE /<id>   (ADMIN veya kendi kaydı)
  Future<Response> deleteById(Request request, String id) async {
    if (!isAdmin(request) && currentUserId(request) != id) {
      return forbidden(
        'Sadece kendi hesabınızı veya ADMIN olarak bu hesabı silebilirsiniz.',
      );
    }

    final result = await _service.deleteById(id);
    return result.toResponse();
  }

  /// DELETE /bulk  →  body: { "ids": ["1", "2", "3"] }   (sadece ADMIN)
  Future<Response> bulkDelete(Request request) async {
    if (!isAdmin(request)) {
      return forbidden('Toplu silme sadece ADMIN tarafından yapılabilir.');
    }

    final ids = parseIds(await readBody(request));
    if (ids == null) return invalidBody();

    final result = await _service.bulkDelete(ids);
    return result.toResponse();
  }
}
