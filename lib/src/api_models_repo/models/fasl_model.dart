import 'package:zenrun/src/api_models_repo/models/task_model.dart';

class FaslModel {
  final int? id;
  final String? title;
  final String? image;
  final String? color;
  final int? lvlAz;
  final int? lvlTa;
  final bool? isActive;
  final bool? isQuiz;
  final int? tartib;
  int currentStep = 0;
  List<TaskModel>? taskList = [];

  FaslModel({
    this.id,
    this.title,
    this.image,
    this.lvlAz,
    this.color,
    this.lvlTa,
    this.isActive,
    this.isQuiz,
    this.tartib,
  });

  factory FaslModel.fromJson(Map<String, dynamic> json) => FaslModel(
    id: json["id"],
    title: json["title"],
    image: json["image"],
    color: json["color"],
    lvlAz: json["lvlAz"],
    lvlTa: json["lvlTa"],
    isActive: json["isActive"],
    isQuiz: json["isQuiz"],
    tartib: json["tartib"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "image": image,
    "color": color,
    "lvlAz": lvlAz,
    "lvlTa": lvlTa,
    "isActive": isActive,
    "isQuiz": isQuiz,
    "tartib": tartib,
  };
}
