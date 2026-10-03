import 'package:base_backend/core/mixins/repository_guard.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/services/mongo/mongo_repository.dart';
import 'package:base_backend/modules/auth/models/refresh_token_record.dart';
import 'package:mongo_dart/mongo_dart.dart';

abstract class IRefreshTokenRepository {
  Future<Result<bool>> save(RefreshTokenRecord record);
  Future<Result<RefreshTokenRecord?>> findByHash(String tokenHash);

  /// Token'ı atomik olarak iptal eder. Sadece o an aktifse true döner;
  /// aynı anda gelen ikinci istek false alır (yarış koşulu koruması).
  Future<Result<bool>> revoke(String tokenHash);

  Future<Result<bool>> revokeFamily(String familyId);
  Future<Result<bool>> deleteExpired(String userId);
}

class RefreshTokenRepository
    with RepositoryGuard
    implements IRefreshTokenRepository {
  static const String collectionName = 'refresh_tokens';

  DbCollection get _collection =>
      MongoDatabase.instance.collection(collectionName);

  @override
  Future<Result<bool>> save(RefreshTokenRecord record) =>
      guardValue<bool>(() async {
        final result = await _collection.insertOne(record.toMap());
        if (!result.isSuccess) {
          throw StateError(
            'Refresh token kaydedilemedi: ${result.writeError?.errmsg}',
          );
        }
        return true;
      });

  @override
  Future<Result<RefreshTokenRecord?>> findByHash(String tokenHash) =>
      guardValue<RefreshTokenRecord?>(() async {
        final doc = await _collection.findOne({'tokenHash': tokenHash});
        return doc == null ? null : RefreshTokenRecord.fromMap(doc);
      });

  @override
  Future<Result<bool>> revoke(String tokenHash) => guardValue<bool>(() async {
    final result = await _collection.updateOne(
      {'tokenHash': tokenHash, 'revoked': false},
      {
        r'$set': {'revoked': true},
      },
    );
    return result.isSuccess && result.nMatched > 0;
  });

  @override
  Future<Result<bool>> revokeFamily(String familyId) =>
      guardValue<bool>(() async {
        final result = await _collection.updateMany(
          {'familyId': familyId},
          {
            r'$set': {'revoked': true},
          },
        );
        return result.isSuccess;
      });

  @override
  Future<Result<bool>> deleteExpired(String userId) =>
      guardValue<bool>(() async {
        final result = await _collection.deleteMany({
          'userId': userId,
          'expiresAt': {r'$lt': DateTime.now().toUtc()},
        });
        return result.isSuccess;
      });
}
