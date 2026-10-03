import 'package:base_backend/core/mixins/controller_helpers.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:base_backend/modules/auth/models/login_payload.dart';
import 'package:base_backend/modules/auth/models/register_payload.dart';
import 'package:base_backend/modules/auth/models/refresh_payload.dart';
import 'package:shelf/shelf.dart';
import 'auth_service.dart';

class AuthController with ControllerHelpers {
  final AuthService _service;

  AuthController(this._service);

  Future<Response> register(Request request) async {
    final body = await readBody(request);
    if (body is! Map<String, dynamic>) return invalidBody();

    final model = parseModel<RegisterPayload>(body, RegisterPayload.fromJson);
    if (model == null) return invalidBody();

    final result = await _service.register(model);
    return result.toResponse(successStatusCode: 201);
  }

  Future<Response> login(Request request) async {
    // 1. Request body'yi JSON olarak oku
    final body = await readBody(request);

    // Body okunamazsa veya JSON/Map formatında değilse erken dönüş (Guard Clause)
    if (body is! Map<String, dynamic>) {
      return invalidBody();
    }

    // 2. Map verisini gelen DTO olan LoginPayload nesnesine dönüştür
    final model = parseModel<LoginPayload>(
      body,
      LoginPayload.fromJson, // LoginPayload içindeki fromJson factory'si
    );

    // Parse başarısızsa (örn. email veya password eksik/hatalı tipteyse) hatayı dön
    if (model == null) {
      return invalidBody();
    }

    // 3. İş mantığını LoginPayload ile servise devret
    // _service.login(...) geriye Result<LoginResponse> döner ve .toResponse() ile HTTP cevabına dönüşür
    final result = await _service.login(model);
    return result.toResponse();
  }

  Future<Response> refresh(Request request) async {
    final body = await readBody(request);
    if (body is! Map<String, dynamic>) return invalidBody();

    final model = parseModel<RefreshPayload>(body, RefreshPayload.fromJson);
    if (model == null) return invalidBody();

    final result = await _service.refresh(model);
    return result.toResponse();
  }

  Future<Response> logout(Request request) async {
    final body = await readBody(request);
    if (body is! Map<String, dynamic>) return invalidBody();

    final model = parseModel<RefreshPayload>(body, RefreshPayload.fromJson);
    if (model == null) return invalidBody();

    final result = await _service.logout(model);
    return result.toResponse();
  }
}
