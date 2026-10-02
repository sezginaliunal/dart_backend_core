import 'package:base_backend/core/services/mongo/mongo_repository.dart';

import '../../../core/result/result.dart';
import 'users_model.dart';

class UsersRepository extends MongoRepository<UsersModel> {
  UsersRepository._internal()
    : super(
        collectionName: 'users',
        fromMap: UsersModel.fromJson,
        toMap: (u) => u.toJson(),
      );

  // Router'da `UsersRepository()` çağırdığınız için factory şart,
  // aksi halde private constructor yüzünden derlenmez.
  static final UsersRepository instance = UsersRepository._internal();
  factory UsersRepository() => instance;

  Future<Result<UsersModel>> findById(String id) => guard(() async {
    final user = await getById(id); // içeride ObjectId.parse yapılır
    return user == null
        ? Result.failure(NotFoundFailure('Users bulunamadı: $id'))
        : Result.success(user);
  });

  Future<Result<List<UsersModel>>> findAll({
    Map<String, dynamic>? filter,
    Map<String, int>? sort,
    int? skip,
    int? limit,
  }) => guardValue(
    () => getAll(filter: filter, sort: sort, skip: skip, limit: limit),
  );

  Future<Result<UsersModel>> createUser(UsersModel user) =>
      guardValue(() => create(user));

  Future<Result<UsersModel>> updateUser(String id, UsersModel user) =>
      guard(() async {
        final updated = await update(id, user);
        if (!updated) {
          return Result.failure(NotFoundFailure('Users bulunamadı: $id'));
        }
        final fresh = await getById(id);
        return fresh == null
            ? Result.failure(NotFoundFailure('Users bulunamadı: $id'))
            : Result.success(fresh);
      });

  Future<Result<bool>> deleteById(String id) => guard(() async {
    final deleted = await delete(id);
    return deleted
        ? const Result.success(true)
        : Result.failure(NotFoundFailure('Users bulunamadı: $id'));
  });
}
