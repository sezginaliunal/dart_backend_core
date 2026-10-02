// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'users_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsersModel _$UsersModelFromJson(Map<String, dynamic> json) => UsersModel(
  id: const ObjectIdConverter().fromJson(json['_id']),
  name: json['name'] as String,
  email: json['email'] as String,
);

Map<String, dynamic> _$UsersModelToJson(UsersModel instance) =>
    <String, dynamic>{
      '_id': ?const ObjectIdConverter().toJson(instance.id),
      'name': instance.name,
      'email': instance.email,
    };
