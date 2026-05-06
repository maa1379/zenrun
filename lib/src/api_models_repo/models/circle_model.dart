import 'package:zenrun/src/api_models_repo/models/follow_model.dart';

class CircleModel {
  final int? id;
  final String? email;
  final String? title;
  final int? count;
  List<FollowModel> followList = [];

  CircleModel({
    this.id,
    this.email,
    this.title,
    this.count,
  });

  factory CircleModel.fromJson(Map<String, dynamic> json) => CircleModel(
    id: json["id"],
    email: json["email"],
    title: json["title"],
    count: json["count"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "title": title,
    "count": count,
  };
}