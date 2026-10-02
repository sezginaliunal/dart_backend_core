// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterPayload _$RegisterPayloadFromJson(Map<String, dynamic> json) =>
    RegisterPayload(
      email: json['email'] as String,
      name: json['name'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$RegisterPayloadToJson(RegisterPayload instance) =>
    <String, dynamic>{
      'email': instance.email,
      'name': instance.name,
      'password': instance.password,
    };
