class LikeModel {
  final int? id;
  final int? postId;
  final String? email;

  LikeModel({
    this.id,
    this.postId,
    this.email,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) => LikeModel(
    id: json["id"],
    postId: json["postId"],
    email: json["Email"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "postId": postId,
    "Email": email,
  };
}