import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/services/mongo/mongo_repository.dart';
import 'package:base_backend/modules/auth/models/auth_user_dto.dart';

abstract class IAuthRepository {
  Future<Result<AuthUserDto?>> findUserByEmail(String email);
  Future<Result<AuthUserDto?>> findUserById(String id);
  Future<Result<AuthUserDto>> createUser(AuthUserDto user);
}

class AuthRepository extends MongoRepository<AuthUserDto>
    implements IAuthRepository {
  AuthRepository()
    : super(
        collectionName: 'users',
        fromMap: AuthUserDto.fromMap,
        toMap: (u) => u.toMap(),
      );

  @override
  Future<Result<AuthUserDto?>> findUserByEmail(String email) =>
      guardValue(() => getFirst({'email': email.trim().toLowerCase()}));

  @override
  Future<Result<AuthUserDto?>> findUserById(String id) =>
      guardValue(() => getById(id));

  @override
  Future<Result<AuthUserDto>> createUser(AuthUserDto user) => guard(() async {
    try {
      return Result.success(await create(user));
    } catch (e) {
      // Unique index ihlali (yarış koşulunda çift kayıt)
      final msg = e.toString();
      if (msg.contains('E11000') || msg.toLowerCase().contains('duplicate')) {
        return Result.failure(
          ValidationFailure(ProjectConstants.failures.emailAlreadyExists),
        );
      }
      rethrow;
    }
  });
}
