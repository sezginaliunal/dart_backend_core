class UsersModel {
  final String id;

  UsersModel({required this.id});

  factory UsersModel.fromJson(Map<String, dynamic> json) {
    return UsersModel(id: json['id'].toString());
  }

  Map<String, dynamic> toJson() => {'id': id};

  static final List<UsersModel> users = List.generate(
    10,
    (index) => UsersModel(id: index.toString()),
  );
}
