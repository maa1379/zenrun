import 'package:zenrun/src/api_models_repo/models/task_model.dart';

class UserTaskModel {
  final int? id;
  final String? email;
  final int? taskId;
  final DateTime? date;
  final bool? isLevelUpDone;
  final String? fileUrl;
  final bool? isSingleUser;
  final bool? isTwoUser;
  final bool? isMultiUser;
  final bool? isDaily;
  final bool? isInvite;
  final int? inviteCount;
  final bool? inviteDone;
  TaskModel? task;

  UserTaskModel({
    this.id,
    this.email,
    this.taskId,
    this.date,
    this.isLevelUpDone,
    this.fileUrl,
    this.isSingleUser,
    this.isTwoUser,
    this.isMultiUser,
    this.isDaily,
    this.isInvite,
    this.inviteCount,
    this.inviteDone,
  });

  factory UserTaskModel.fromJson(Map<String, dynamic> json) => UserTaskModel(
    id: json["id"],
    email: json["email"],
    taskId: json["taskId"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    isLevelUpDone: json["isLevelUpDone"],
    fileUrl: json["fileURL"],
    isSingleUser: json["isSingleUser"],
    isTwoUser: json["isTwoUser"],
    isMultiUser: json["isMultiUser"],
    isDaily: json["isDaily"],
    isInvite: json["isInvite"],
    inviteCount: json["InviteCount"],
    inviteDone: json["InviteDone"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "taskId": taskId,
    "date": date?.toIso8601String(),
    "isLevelUpDone": isLevelUpDone,
    "fileURL": fileUrl,
    "isSingleUser": isSingleUser,
    "isTwoUser": isTwoUser,
    "isMultiUser": isMultiUser,
    "isDaily": isDaily,
    "isInvite": isInvite,
    "InviteCount": inviteCount,
    "InviteDone": inviteDone,
  };
}
