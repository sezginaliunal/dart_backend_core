import 'package:mongo_dart/mongo_dart.dart';

class AuthUserDto {
  final String id;
  final String email;
  final String name;
  final String passwordHash;

  AuthUserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
  });

  factory AuthUserDto.fromMap(Map<String, dynamic> map) => AuthUserDto(
    id: (map['_id'] as ObjectId).oid,
    email: map['email'] as String,
    name: (map['name'] as String?) ?? '',
    passwordHash: map['passwordHash'] as String,
  );

  /// '_id' yok; MongoRepository.create zaten remove('_id') yapıyor,
  /// Mongo kendisi üretir.
  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'passwordHash': passwordHash,
  };
}
