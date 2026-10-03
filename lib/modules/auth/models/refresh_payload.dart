import 'package:json_annotation/json_annotation.dart';

part 'refresh_payload.g.dart';

/// /auth/refresh ve /auth/logout isteklerinin gövdesi.
@JsonSerializable()
class RefreshPayload {
  final String refreshToken;

  RefreshPayload({required this.refreshToken});

  factory RefreshPayload.fromJson(Map<String, dynamic> json) =>
      _$RefreshPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshPayloadToJson(this);
}
