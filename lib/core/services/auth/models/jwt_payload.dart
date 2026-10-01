import 'package:json_annotation/json_annotation.dart';

part 'jwt_payload.g.dart';

@JsonSerializable(explicitToJson: true, createFactory: false)
class JwtPayload {
  final String id;
  final String issuer;
  final JwtPayloadService service;

  JwtPayload({required this.id, required this.issuer, required this.service});

  Map<String, dynamic> toJson() => _$JwtPayloadToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class JwtPayloadService {
  final String id;
  final String loc;

  JwtPayloadService({required this.id, required this.loc});

  Map<String, dynamic> toJson() => _$JwtPayloadServiceToJson(this);
}
