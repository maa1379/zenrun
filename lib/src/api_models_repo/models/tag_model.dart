import 'package:zenrun/src/api_models_repo/models/profile_model.dart';

class TagModel {
  final int? id;
  final String? email;
  final String? friendEmail;
  final String? description;
  final int? circleId;
  final int? taskId;
  final bool? isRead;
  final DateTime? date;
  final String? type;

  TagModel({
    this.id,
    this.email,
    this.friendEmail,
    this.description,
    this.circleId,
    this.taskId,
    this.isRead,
    this.date,
    this.type,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) => TagModel(
    id: json["id"],
    email: json["email"],
    friendEmail: json["friendEmail"],
    description: json["description"],
    circleId: json["circleId"],
    taskId: json["taskId"],
    isRead: json["isRead"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "friendEmail": friendEmail,
    "description": description,
    "circleId": circleId,
    "taskId": taskId,
    "isRead": isRead,
    "date": date?.toIso8601String(),
    "type": type,
  };
}


class TagParams {
  final String friendEmail;
  final String type; // 'task' یا 'social'
  final String description;
  final String isRead;
  final String circleId;
  final String taskId;
  final DateTime date;
  ProfileModel? profileModel;

  TagParams({
    required this.friendEmail,
    required this.type,
    required this.description,
    required this.isRead,
    required this.circleId,
    required this.taskId,
    required this.date,
    this.profileModel
  });
}