import '../../../core/result/result.dart';
import 'users_model.dart';
import 'users_repository.dart';

class UsersService {
  final UsersRepository _repository;

  UsersService(this._repository);

  Future<Result<UsersModel>> getById(String id) async {
    // Validasyon veya İş Kuralı Kontrolü
    if (id.trim().isEmpty) {
      return const Result.failure(ValidationFailure('Geçersiz ID parametresi'));
    }

    return await _repository.findById(id);
  }

  Future<Result<List<UsersModel>>> findAll() async {
    return await _repository.findAll();
  }

  Future<Result<bool>> deleteById(String id) async {
    return await _repository.deleteById(id);
  }
}
