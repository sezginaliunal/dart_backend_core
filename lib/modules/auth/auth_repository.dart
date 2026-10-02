import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/services/mongo/mongo_repository.dart';
import 'package:base_backend/modules/auth/models/auth_user_dto.dart';
import 'package:base_backend/modules/auth/models/register_payload.dart';
// MongoRepository'nin bulunduğu dosyanın import'unu kendi yoluna göre ekle:
// import 'package:base_backend/core/database/mongo_repository.dart';

abstract class IAuthRepository {
  Future<Result<RegisterPayload>> register(RegisterPayload payload);
  Future<Result<AuthUserDto?>> findUserByEmail(String email);
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
  Future<Result<RegisterPayload>> register(RegisterPayload payload) async {
    try {
      final email = payload.email.trim().toLowerCase();

      // E-posta zaten kayıtlı mı?
      final existing = await getFirst({'email': email});
      if (existing != null) {
        return Result.failure(ValidationFailure('Bu e-posta zaten kayıtlı.'));
      }

      await create(
        AuthUserDto(
          id: '', // Mongo üretecek
          email: email,
          name: payload.name,
          passwordHash: payload.password, // service'te zaten hash'lendi
        ),
      );

      // Hash'i client'a geri döndürme
      return Result.success(payload.copyWith(email: email, password: ''));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthUserDto?>> findUserByEmail(String email) async {
    try {
      final user = await getFirst({'email': email.trim().toLowerCase()});
      return Result.success(user);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
