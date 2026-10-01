import '../../../core/result/result.dart';
import 'users_model.dart';

class UsersRepository {
  Future<Result<UsersModel>> findById(String id) async {
    try {
      // TODO: Veritabanı sorgusu (SQL / ORM)
      // Örnek sahte veri kontrolü:
      if (id == '404') {
        return Result.failure(const NotFoundFailure('Users bulunamadı'));
      }

      final model = UsersModel(id: id);
      return Result.success(model);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<UsersModel>>> findAll() async {
    try {
      return Result.success(UsersModel.users);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<bool>> deleteById(String id) async {
    try {
      return Result.success(true);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
