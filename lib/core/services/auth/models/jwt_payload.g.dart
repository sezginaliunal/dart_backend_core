// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$JwtPayloadToJson(JwtPayload instance) =>
    <String, dynamic>{
      'id': instance.id,
      'issuer': instance.issuer,
      'service': instance.service.toJson(),
    };

Map<String, dynamic> _$JwtPayloadServiceToJson(JwtPayloadService instance) =>
    <String, dynamic>{'id': instance.id, 'loc': instance.loc};
