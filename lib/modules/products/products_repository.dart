import 'package:base_backend/core/result/result.dart';
import 'products_model.dart';

class ProductsRepository {
  // ───────────── READ ─────────────

  Future<Result<ProductsModel>> findById(String id) async {
    try {
      // TODO: Veritabanı sorgusu (SQL / ORM)
      // Örnek sahte veri kontrolü:
      if (id == '404') {
        return Result.failure(const NotFoundFailure('Products bulunamadı'));
      }

      final model = ProductsModel(id: id);
      return Result.success(model);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<ProductsModel>>> findAll() async {
    try {
      return Result.success(ProductsModel.mock);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  // ───────────── CREATE ─────────────

  Future<Result<ProductsModel>> create(ProductsModel model) async {
    try {
      // TODO: INSERT sorgusu
      return Result.success(model);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<ProductsModel>>> bulkCreate(
    List<ProductsModel> models,
  ) async {
    try {
      // TODO: Tek transaction içinde toplu INSERT
      return Result.success(models);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  // ───────────── UPDATE ─────────────

  Future<Result<ProductsModel>> update(String id, ProductsModel model) async {
    try {
      // TODO: UPDATE sorgusu
      if (id == '404') {
        return Result.failure(const NotFoundFailure('Products bulunamadı'));
      }

      return Result.success(model);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<ProductsModel>>> bulkUpdate(
    List<ProductsModel> models,
  ) async {
    try {
      // TODO: Tek transaction içinde toplu UPDATE
      // Biri bile bulunamazsa hepsini geri al (rollback)
      if (models.any((m) => m.id == '404')) {
        return Result.failure(const NotFoundFailure('Products bulunamadı'));
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
