class JwtPayload {
  final String id;
  final String role;

  const JwtPayload({required this.id, required this.role});

  Map<String, dynamic> toJson() => {'id': id, 'role': role};
}
