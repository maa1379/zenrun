class QuizModel {
  final int? id;
  final int? taskId;
  final String? passingScore;
  final int? rCoin;
  final int? zCoin;
  final int? sCoin;
  final int? coin;
  final int? faslid;
  final String? color;
  List<QuestionModel> questionList = [];

  QuizModel({
    this.id,
    this.taskId,
    this.passingScore,
    this.rCoin,
    this.zCoin,
    this.sCoin,
    this.color,
    this.coin,
    this.faslid,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) => QuizModel(
    id: json["id"],
    taskId: json["taskId"],
    passingScore: json["passingScore"],
    rCoin: json["RCoin"],
    zCoin: json["ZCoin"],
    sCoin: json["SCoin"],
    color: json["color"],
    coin: json["Coin"],
    faslid: json["faslid"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "taskId": taskId,
    "passingScore": passingScore,
    "RCoin": rCoin,
    "color": color,
    "ZCoin": zCoin,
    "SCoin": sCoin,
    "Coin": coin,
    "faslid": faslid,
  };
}

class QuestionModel {
  final int? id;
  final String? soal;
  final String? gozine1;
  final String? gozine2;
  final String? gozine3;
  final String? gozine4;
  final bool? isActive;
  final String? gozineTrue;
  final int? taskId;
  final int? quizId;
  bool isSelected = false;
  List<QModel> qList = [];

  QuestionModel({
    this.id,
    this.soal,
    this.gozine1,
    this.gozine2,
    this.gozine3,
    this.gozine4,
    this.isActive,
    this.gozineTrue,
    this.taskId,
    this.quizId,
  }) {
    if (gozine1 != null) {
      qList.add(QModel(gozine1!));
    }
    if (gozine2 != null) {
      qList.add(QModel(gozine2!));
    }
    if (gozine3 != null) {
      qList.add(QModel(gozine3!));
    }
    if (gozine4 != null) {
      qList.add(QModel(gozine4!));
    }
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
    id: json["id"],
    soal: json["soal"],
    gozine1: json["gozine1"],
    gozine2: json["gozine2"],
    gozine3: json["gozine3"],
    gozine4: json["gozine4"],
    isActive: json["isActive"],
    gozineTrue: json["gozineTrue"],
    taskId: json["taskId"],
    quizId: json["quizId"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "soal": soal,
    "gozine1": gozine1,
    "gozine2": gozine2,
    "gozine3": gozine3,
    "gozine4": gozine4,
    "isActive": isActive,
    "gozineTrue": gozineTrue,
    "taskId": taskId,
    "quizId": quizId,
  };
}

class AnswerData {
  String questionId;
  String quizId;
  String gozineEntekhabi;
  bool isTrue;

  AnswerData({
    required this.questionId,
    required this.quizId,
    required this.gozineEntekhabi,
    required this.isTrue,
  });
}

class QModel {
  String q;
  bool isSelected = false;

  QModel(this.q);
}


class UserQuizModel {
  final int? id;
  final int? quizId;
  final String? email;
  final bool? isPassed;
  final DateTime? date;
  final int? taskId;
  final bool? isFinish;

  UserQuizModel({
    this.id,
    this.quizId,
    this.email,
    this.isPassed,
    this.date,
    this.taskId,
    this.isFinish,
  });

  factory UserQuizModel.fromJson(Map<String, dynamic> json) => UserQuizModel(
    id: json["id"],
    quizId: json["quizId"],
    email: json["email"],
    isPassed: json["isPassed"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    taskId: json["taskId"],
    isFinish: json["isFinish"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "quizId": quizId,
    "email": email,
    "isPassed": isPassed,
    "date": date?.toIso8601String(),
    "taskId": taskId,
    "isFinish": isFinish,
  };
}

