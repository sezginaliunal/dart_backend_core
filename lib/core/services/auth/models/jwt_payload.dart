import 'package:json_annotation/json_annotation.dart';

part 'jwt_payload.g.dart';

@JsonSerializable(explicitToJson: true, createFactory: false)
class JwtPayload {
  final String id;
  final String issuer;

  JwtPayload({required this.id, required this.issuer});

  Map<String, dynamic> toJson() => _$JwtPayloadToJson(this);
}
