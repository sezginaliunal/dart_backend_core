import 'dart:io';

/// Kullanım:
///   dart run scripts/create_module.dart <modul_adi> [--no-build]
///
/// --no-build : build_runner'ı otomatik çalıştırma
void main(List<String> args) async {
  final flags = args.where((a) => a.startsWith('--')).toSet();
  final positional = args.where((a) => !a.startsWith('--')).toList();

  if (positional.isEmpty) {
    print('❌ Hata: Modül adı giriniz!');
    print(
      'Kullanım: dart run scripts/create_module.dart <modul_adi> [--no-build]',
    );
    exit(1);
  }

  final snake = _toSnakeCase(positional[0].trim());
  final pascal = _toPascalCase(snake);
  final pkg = _readPackageName();

  final dir = Directory('lib/modules/$snake');

  if (dir.existsSync()) {
    print('⚠️  Uyarı: "$snake" modülü zaten mevcut!');
    exit(1);
  }

  _checkDependencies();

  dir.createSync(recursive: true);
  print('🚀 "$snake" modülü oluşturuluyor...\n');

  final files = <String, String>{
    // 1. MODEL (json_serializable)
    '${snake}_model.dart':
        '''
import 'package:json_annotation/json_annotation.dart';

part '${snake}_model.g.dart';

@JsonSerializable()
class ${pascal}Model {
  @JsonKey(fromJson: _idFromJson)
  final String id;

  const ${pascal}Model({required this.id});

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) =>
      _\$${pascal}ModelFromJson(json);

  Map<String, dynamic> toJson() => _\$${pascal}ModelToJson(this);

  // id int olarak gelse bile String'e çevirir
  static String _idFromJson(Object? value) => value.toString();

  // TODO: Veritabanı bağlanınca sil
  static final List<${pascal}Model> mock = List.generate(
    10,
    (index) => ${pascal}Model(id: index.toString()),
  );
}
''',

    // 2. REPOSITORY
    '${snake}_repository.dart':
        '''
import 'package:$pkg/core/result/result.dart';
import '${snake}_model.dart';

class ${pascal}Repository {
  // ───────────── READ ─────────────

  Future<Result<${pascal}Model>> findById(String id) async {
    try {
      // TODO: Veritabanı sorgusu (SQL / ORM)
      // Örnek sahte veri kontrolü:
      if (id == '404') {
        return Result.failure(const NotFoundFailure('$pascal bulunamadı'));
      }

      final model = ${pascal}Model(id: id);
      return Result.success(model);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<${pascal}Model>>> findAll() async {
    try {
      return Result.success(${pascal}Model.mock);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  // ───────────── CREATE ─────────────

  Future<Result<${pascal}Model>> create(${pascal}Model model) async {
    try {
      // TODO: INSERT sorgusu
      return Result.success(model);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<${pascal}Model>>> bulkCreate(
    List<${pascal}Model> models,
  ) async {
    try {
      // TODO: Tek transaction içinde toplu INSERT
      return Result.success(models);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  // ───────────── UPDATE ─────────────

  Future<Result<${pascal}Model>> update(String id, ${pascal}Model model) async {
    try {
      // TODO: UPDATE sorgusu
      if (id == '404') {
        return Result.failure(const NotFoundFailure('$pascal bulunamadı'));
      }

      return Result.success(model);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<${pascal}Model>>> bulkUpdate(
    List<${pascal}Model> models,
  ) async {
    try {
      // TODO: Tek transaction içinde toplu UPDATE
      // Biri bile bulunamazsa hepsini geri al (rollback)
      if (models.any((m) => m.id == '404')) {
        return Result.failure(const NotFoundFailure('$pascal bulunamadı'));
      }

      return Result.success(models);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  // ───────────── DELETE ─────────────

  Future<Result<bool>> deleteById(String id) async {
    try {
      // TODO: DELETE sorgusu
      return Result.success(true);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<bool>> bulkDelete(List<String> ids) async {
    try {
      // TODO: WHERE id IN (...) ile toplu silme
      return Result.success(true);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
''',

    // 3. SERVICE
    '${snake}_service.dart':
        '''
import 'package:$pkg/core/result/result.dart';
import '${snake}_model.dart';
import '${snake}_repository.dart';

class ${pascal}Service {
  final ${pascal}Repository _repository;

  ${pascal}Service(this._repository);

  /// Toplu işlemlerde tek seferde izin verilen maksimum kayıt sayısı
  static const int maxBulkSize = 100;

  // ───────────── READ ─────────────

  Future<Result<${pascal}Model>> getById(String id) async {
    // Validasyon veya İş Kuralı Kontrolü
    if (id.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Geçersiz ID parametresi'));
    }

    return await _repository.findById(id);
  }

  Future<Result<List<${pascal}Model>>> findAll() async {
    return await _repository.findAll();
  }

  // ───────────── CREATE ─────────────

  Future<Result<${pascal}Model>> create(${pascal}Model model) async {
    return await _repository.create(model);
  }

  Future<Result<List<${pascal}Model>>> bulkCreate(
    List<${pascal}Model> models,
  ) async {
    if (models.isEmpty) {
      return const Result.failure(ValidationFailure('Liste boş olamaz'));
    }
    if (models.length > maxBulkSize) {
      return Result.failure(
        ValidationFailure('Tek seferde en fazla \$maxBulkSize kayıt işlenebilir'),
      );
    }

    return await _repository.bulkCreate(models);
  }

  // ───────────── UPDATE ─────────────

  Future<Result<${pascal}Model>> update(String id, ${pascal}Model model) async {
    if (id.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Geçersiz ID parametresi'));
    }

    return await _repository.update(id, model);
  }

  Future<Result<List<${pascal}Model>>> bulkUpdate(
    List<${pascal}Model> models,
  ) async {
    if (models.isEmpty) {
      return const Result.failure(ValidationFailure('Liste boş olamaz'));
    }
    if (models.length > maxBulkSize) {
      return Result.failure(
        ValidationFailure('Tek seferde en fazla \$maxBulkSize kayıt işlenebilir'),
      );
    }
    if (models.any((m) => m.id.trim().isEmpty)) {
      return const Result.failure(
        ValidationFailure('Tüm kayıtlarda geçerli bir id olmalı'),
      );
    }

    return await _repository.bulkUpdate(models);
  }

  // ───────────── DELETE ─────────────

  Future<Result<bool>> deleteById(String id) async {
    if (id.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Geçersiz ID parametresi'));
    }

    return await _repository.deleteById(id);
  }

  Future<Result<bool>> bulkDelete(List<String> ids) async {
    if (ids.isEmpty) {
      return const Result.failure(ValidationFailure('ID listesi boş olamaz'));
    }
    if (ids.length > maxBulkSize) {
      return Result.failure(
        ValidationFailure('Tek seferde en fazla \$maxBulkSize kayıt işlenebilir'),
      );
    }
    if (ids.any((id) => id.trim().isEmpty)) {
      return const Result.failure(ValidationFailure('Geçersiz ID içeriyor'));
    }

    return await _repository.bulkDelete(ids);
  }
}
''',

    // 4. CONTROLLER
    '${snake}_controller.dart':
        '''
import 'dart:convert';

import 'package:$pkg/core/result/result.dart';
import 'package:$pkg/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';
import '${snake}_model.dart';
import '${snake}_service.dart';

class ${pascal}Controller {
  final ${pascal}Service _service;

  ${pascal}Controller(this._service);

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
  ${pascal}Model? _parseModel(Map<String, dynamic> json, {String? forceId}) {
    try {
      final data = Map<String, dynamic>.from(json);
      data['id'] = forceId ?? data['id'] ?? _generateId();
      return ${pascal}Model.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Body'den model listesi üretir. Tek bir eleman bile hatalıysa null döner.
  List<${pascal}Model>? _parseList(Object? body, {bool requireId = false}) {
    if (body is! List) return null;

    final models = <${pascal}Model>[];
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
''',

    // 5. ROUTER (AppModule)
    '${snake}_router.dart':
        '''
import 'package:$pkg/core/middlewares/auth_middleware.dart';
import 'package:$pkg/core/module/app_module.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '${snake}_controller.dart';
import '${snake}_repository.dart';
import '${snake}_service.dart';

class ${pascal}Router implements AppModule {
  ${pascal}Router()
      : _controller = ${pascal}Controller(${pascal}Service(${pascal}Repository()));

  final ${pascal}Controller _controller;

  @override
  String get path => '/api/v1/$snake';

  Router get _internalRouter {
    final router = Router();

    // Koleksiyon
    router.get('/', _controller.findAll);
    router.post('/', _controller.create);

    // ⚠️ Bulk rotaları '/<id>' rotalarından ÖNCE tanımlanmalı,
    // aksi halde "bulk" bir id olarak yakalanır.
    router.post('/bulk', _controller.bulkCreate);
    router.put('/bulk', _controller.bulkUpdate);
    router.delete('/bulk', _controller.bulkDelete);

    // Tekil kayıt
    router.get('/<id>', _controller.getById);
    router.put('/<id>', _controller.update);
    router.delete('/<id>', _controller.deleteById);

    return router;
  }

  @override
  Handler get handler {
    return Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(_internalRouter.call);
  }
}
''',
  };

  // Dosyaları diske yaz
  files.forEach((filename, content) {
    final file = File('${dir.path}/$filename');
    file.writeAsStringSync(content.trimLeft());
    print('  ├─ ✅ ${file.path}');
  });

  print('\n✨ "$pascal" modülü oluşturuldu!');
  print('\n🛣️  Rotalar (/api/v1/$snake):');
  print('   GET     /          → findAll');
  print('   POST    /          → create');
  print('   POST    /bulk      → bulkCreate   (ADMIN)');
  print('   PUT     /bulk      → bulkUpdate   (ADMIN)');
  print('   DELETE  /bulk      → bulkDelete   (ADMIN)');
  print('   GET     /<id>      → getById');
  print('   PUT     /<id>      → update       (ADMIN veya kendisi)');
  print('   DELETE  /<id>      → deleteById   (ADMIN veya kendisi)');

  // json_serializable .g.dart dosyasını üret
  if (flags.contains('--no-build')) {
    print('\nℹ️  .g.dart dosyası için şunu çalıştır:');
    print('   dart run build_runner build --delete-conflicting-outputs');
  } else {
    print('\n⚙️  build_runner çalışıyor...\n');
    final process = await Process.start(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      mode: ProcessStartMode.inheritStdio,
      runInShell: true,
    );
    final code = await process.exitCode;
    if (code == 0) {
      print('\n✅ ${snake}_model.g.dart üretildi.');
    } else {
      print(
        '\n❌ build_runner hata verdi (kod: $code). Bağımlılıkları kontrol et.',
      );
    }
  }

  print('\n📌 Unutma: "${pascal}Router()" sınıfını ana modül listene ekle.');
}

/// pubspec.yaml içinden paket adını okur (yoksa base_backend)
String _readPackageName() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) return 'base_backend';

  final match = RegExp(
    r'^name:\s*(\S+)',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());

  return match?.group(1) ?? 'base_backend';
}

/// Gerekli paketler pubspec'te var mı kontrol eder
void _checkDependencies() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) return;

  final content = pubspec.readAsStringSync();
  final missingRuntime = !content.contains('json_annotation');
  final missingDev =
      !content.contains('json_serializable') ||
      !content.contains('build_runner');

  if (missingRuntime || missingDev) {
    print('⚠️  Eksik paketler var, şunları çalıştır:');
    if (missingRuntime) print('   dart pub add json_annotation');
    if (missingDev)
      print('   dart pub add --dev build_runner json_serializable');
    print('');
  }
}

String _toSnakeCase(String text) {
  return text
      .replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)!.toLowerCase()}',
      )
      .replaceAll(RegExp(r'^_'), '')
      .replaceAll('-', '_')
      .replaceAll(RegExp(r'_+'), '_')
      .toLowerCase();
}

String _toPascalCase(String text) {
  return text
      .split(RegExp(r'[-_]'))
      .map(
        (word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join('');
}
