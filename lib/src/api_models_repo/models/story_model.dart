import 'package:zenrun/src/api_models_repo/models/profile_model.dart';

enum MediaType { image, video }

class StoryModel {
  final int? id;
  final String? fileUrl;
  final DateTime? date;
  final String? email;
  List<StoryModel>? stories;
  ProfileModel? profile;

  StoryModel({this.id, this.fileUrl, this.date, this.email, this.stories});

  factory StoryModel.fromJson(Map<String, dynamic> json) => StoryModel(
    id: json["id"],
    fileUrl: json["fileURL"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    email: json["email"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "fileURL": fileUrl,
    "date": date?.toIso8601String(),
    "email": email,
  };
}
