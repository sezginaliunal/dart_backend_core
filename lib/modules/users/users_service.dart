import '../../../core/result/result.dart';
import 'users_model.dart';
import 'users_repository.dart';

class UsersService {
  final UsersRepository _repository;

  UsersService(this._repository);

  Future<Result<UsersModel>> getById(String id) async {
    if (id.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Geçersiz ID parametresi'));
    }
    return await _repository.findById(id);
  }

  Future<Result<List<UsersModel>>> findAll({int? skip, int? limit}) async {
    return await _repository.findAll(
      sort: {'name': 1},
      skip: skip,
      limit: limit,
    );
  }

  Future<Result<bool>> deleteById(String id) async {
    if (id.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Geçersiz ID parametresi'));
    }
    return await _repository.deleteById(id);
  }
}
