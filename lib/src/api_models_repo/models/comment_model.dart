class CommentModel {
  final int? id;
  final int? postId;
  String? comment1;
  final String? email;
  final String? userImage;
  final String? userName;
  final String? userFamily;
  final int? replyId;
  final String? replyTitle;
  final DateTime? date;

  CommentModel({
    this.id,
    this.postId,
    this.comment1,
    this.email,
    this.userImage,
    this.userName,
    this.userFamily,
    this.date,
    this.replyId,
    this.replyTitle,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: json["id"],
    postId: json["postId"],
    comment1: json["comment1"],
    replyId: json["replyId"],
    replyTitle: json["replyTitle"],
    email: json["Email"],
    userImage: json["userImage"],
    userName: json["userName"],
    userFamily: json["userFamily"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "postId": postId,
    "replyId": replyId,
    "replyTitle": replyTitle,
    "comment1": comment1,
    "Email": email,
    "userImage": userImage,
    "userName": userName,
    "userFamily": userFamily,
    "date": date?.toIso8601String(),
  };
}
