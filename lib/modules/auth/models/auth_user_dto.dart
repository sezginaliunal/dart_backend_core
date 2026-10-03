import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/result/api_serializable.dart';
import 'package:mongo_dart/mongo_dart.dart';

class AuthUserDto implements ApiSerializable {
  final String id;
  final String email;
  final String name;
  final String passwordHash;
  final String role;

  AuthUserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
    this.role = ProjectConstants.roleUser,
  });

  factory AuthUserDto.fromMap(Map<String, dynamic> map) => AuthUserDto(
    id: (map['_id'] as ObjectId).oid,
    email: map['email'] as String,
    name: (map['name'] as String?) ?? '',
    passwordHash: map['passwordHash'] as String,
    role: (map['role'] as String?) ?? ProjectConstants.roleUser,
  );

  /// '_id' yok; MongoRepository.create zaten remove('_id') yapıyor,
  /// Mongo kendisi üretir.
  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'passwordHash': passwordHash,
    'role': role,
  };

  /// API cevabı: passwordHash asla dışarı çıkmaz.
  @override
  Map<String, dynamic> toApiJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
  };
}
