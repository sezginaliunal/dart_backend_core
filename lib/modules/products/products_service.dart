import 'package:base_backend/core/result/result.dart';
import 'products_model.dart';
import 'products_repository.dart';

class ProductsService {
  final ProductsRepository _repository;

  ProductsService(this._repository);

  /// Toplu işlemlerde tek seferde izin verilen maksimum kayıt sayısı
  static const int maxBulkSize = 100;

  // ───────────── READ ─────────────

  Future<Result<ProductsModel>> getById(String id) async {
    // Validasyon veya İş Kuralı Kontrolü
    if (id.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Geçersiz ID parametresi'));
    }

    return await _repository.findById(id);
  }

  Future<Result<List<ProductsModel>>> findAll() async {
    return await _repository.findAll();
  }

  // ───────────── CREATE ─────────────

  Future<Result<ProductsModel>> create(ProductsModel model) async {
    return await _repository.create(model);
  }

  Future<Result<List<ProductsModel>>> bulkCreate(
    List<ProductsModel> models,
  ) async {
    if (models.isEmpty) {
      return const Result.failure(ValidationFailure('Liste boş olamaz'));
    }
    if (models.length > maxBulkSize) {
      return Result.failure(
        ValidationFailure('Tek seferde en fazla $maxBulkSize kayıt işlenebilir'),
      );
    }

    return await _repository.bulkCreate(models);
  }

  // ───────────── UPDATE ─────────────

  Future<Result<ProductsModel>> update(String id, ProductsModel model) async {
    if (id.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Geçersiz ID parametresi'));
    }

    return await _repository.update(id, model);
  }

  Future<Result<List<ProductsModel>>> bulkUpdate(
    List<ProductsModel> models,
  ) async {
    if (models.isEmpty) {
      return const Result.failure(ValidationFailure('Liste boş olamaz'));
    }
    if (models.length > maxBulkSize) {
      return Result.failure(
        ValidationFailure('Tek seferde en fazla $maxBulkSize kayıt işlenebilir'),
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
        ValidationFailure('Tek seferde en fazla $maxBulkSize kayıt işlenebilir'),
      );
    }
    if (ids.any((id) => id.trim().isEmpty)) {
      return const Result.failure(ValidationFailure('Geçersiz ID içeriyor'));
    }

    return await _repository.bulkDelete(ids);
  }
}
