import 'package:flutter/cupertino.dart';
import 'package:zenrun/src/api_models_repo/models/comment_model.dart';
import '../../../core/network/api_helper.dart';
import '../../social_pages/widgets/video_manager.dart';
import 'like_model.dart';

class PostModel {
  final int? id;
  int? Amount;
  final String? image1;
  final String? video;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? description;
  final String? userImage;
  final DateTime? date;
  final String? label;
  final String? labelColor;
  final bool? isReels;
  final bool? isAccept;
  final bool? isLikeToCoin;
  final String? userEmail;
  final String? userName;
  List<String> mediaList;
  int likeCount = 0;
  List<LikeModel> likeList = [];
  List<CommentModel> commentList = [];
  FlickMultiManager flickMultiManager = FlickMultiManager();
  bool show = false;
  bool like = false;
  bool isLike = false;
  List<Size?> mediaSizes= [];
  String? circleId;
  String? circleTitle;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final PageController pageController = PageController();

  @JsonKey(includeFromJson: false, includeToJson: false)
  final TransformationController transformationController = TransformationController();

  @JsonKey(includeFromJson: false, includeToJson: false)
  int activeIndex = 0;


  PostModel({
    this.id,
    this.image1,
    this.video,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.description,
    this.userImage,
    this.userName,
    this.date,
    required this.mediaList,
    this.label,
    this.Amount,
    this.labelColor,
    this.isReels,
    this.isAccept,
    this.isLikeToCoin,
    this.userEmail,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {

    List<String> media = [
      json['image1'],
      json['image2'],
      json['image3'],
      json['image4'],
      json['image5'],
      json['video'],
    ].where((item) => item != null && item.toString().isNotEmpty).map((item) => item.toString()).toList();

    return PostModel(
    id: json["id"],
    mediaList: media,
    image1: fixDoubleSlashes(json["image1"]),
    video: fixDoubleSlashes(json["video"]),
    image2: fixDoubleSlashes(json["image2"]),
    image3: fixDoubleSlashes(json["image3"]),
    image4: fixDoubleSlashes(json["image4"]),
    image5: fixDoubleSlashes(json["image5"]),
    description: json["description"],
    Amount: json["Amount"],
    userName: json["userName"],
    userImage: json["userImage"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    label: json["label"],
    labelColor: json["labelColor"],
    isReels: json["isReels"] ?? false,
    isAccept: json["isAccept"],
    isLikeToCoin: json["isLikeToCoin"],
    userEmail: json["userEmail"],
  );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "image1": image1,
    "video": video,
    "Amount": Amount,
    "image2": image2,
    "image3": image3,
    "image4": image4,
    "userName": userName,
    "image5": image5,
    "description": description,
    "userImage": userImage,
    "date": date?.toIso8601String(),
    "label": label,
    "labelColor": labelColor,
    "isReels": isReels,
    "isAccept": isAccept,
    "isLikeToCoin": isLikeToCoin,
    "userEmail": userEmail,
  };
}


class JsonKey {
  final bool includeFromJson;
  final bool includeToJson;
  const JsonKey({this.includeFromJson = true, this.includeToJson = true});
}