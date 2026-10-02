import 'package:base_backend/core/result/result.dart';

/// try/catch tekrarını bitiren ortak yardımcı.
/// MongoRepository'ye `with RepositoryGuard` olarak eklenir.
mixin RepositoryGuard {
  /// Aksiyon zaten Result dönüyorsa (örn. NotFound kontrolü yapılıyorsa).
  Future<Result<R>> guard<R>(Future<Result<R>> Function() action) async {
    try {
      return await action();
    } on ArgumentError catch (e) {
      // Geçersiz ObjectId (ObjectId.parse) vb.
      return Result.failure(ValidationFailure(e.message.toString()));
    } on FormatException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  /// Aksiyon düz değer dönüyorsa otomatik Success'e sarar.
  Future<Result<R>> guardValue<R>(Future<R> Function() action) =>
      guard(() async => Result.success(await action()));
}
