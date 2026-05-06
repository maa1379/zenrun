import '../../core/network/DataState.dart';
import '../../core/network/api_helper.dart';

class AiService {
  AiService._();

  static AiService get instance => AiService._();

  Future<DataState<String>> registerAi({
    String? name,
    int? height,
    int? weight,
    int? age,
    String? gender,
    int? exerciseHours,
    String? country,
    String? city,
    String? username,
    String? password,
    String? email,
    String? language,
  }) async {
    try {
      final res = await ApiHelper.makePostForAi(
        path: "register",
        retryCount: 1,
        body: {
          "name": name,
          "height": height,
          "weight": weight,
          "age": age,
          "gender": gender,
          "exercise_hours": exerciseHours,
          "country": country,
          "city": city,
          "username": username,
          "password": password,
          "email": email,
          "language": language,
        },
      );
      return DataSuccess(res.data);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> loginAi({
    String? username,
    String? password,
  }) async {
    try {
      final res = await ApiHelper.makePostForAi(
        path: "login",
        body: {"username": username?.toLowerCase(), "password": password},
      );
      return DataSuccess(res.data.toString());
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> aiTextChat({
    String? username,
    String? msg,
    String? tone,
  }) async {
    try {
      final res = await ApiHelper.makePostForAi(
        path: "user/chat",
        body: {
          "username": username,
          "user_message": msg,
          "selected_tone": "friendly",
        },
      );
      return DataSuccess(res.data['response']);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> aiVoiceChat({
    String? username,
    String? audioUrl,
    String? tone,
  }) async {
    try {
      final res = await ApiHelper.makePostForAi(
        path: "voice_text",
        body: {
          "username": username,
          "audio_url": audioUrl,
          "selected_tone": tone,
        },
      );
      return DataSuccess(res.data['response']);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> aiUpdateWeight({
    String? username,
    String? password,
    String? newWeight,
  }) async {
    try {
      final res = await ApiHelper.makePostForAi(
        path: "admin/update_weight",
        body: {
          "username": username,
          "password": password,
          "new_weight": newWeight,
        },
      );
      return DataSuccess(res.data);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<AiImageModel>>> aiProcessImage({String? url}) async {
    try {
      List<AiImageModel> list = [];
      final res = await ApiHelper.makePostForAi(
        path: "process-image",
        body: {"image_path": url},
      );
      for (var i in res.data['results']) {
        list.add(AiImageModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> aiSubmitReport1({
    String? username,
    String? msg,
  }) async {
    try {
      final res = await ApiHelper.makePostForAi(
        path: "submit-report-F3_AI_1",
        body: {
          "user_name_F3_AI_1": username,
          "report_text_F3_AI_1": msg,
          "max_tokens_F3_AI_1": 300,
        },
      );
      return DataSuccess(res.data);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> aiSubmitGodThanking({
    String? username,
    String? msg,
  }) async {
    try {
      final res = await ApiHelper.makePostForAi(
        path: "submit-GodThanking-F2_AI_1",
        body: {
          "user_name_F2_AI_1": username,
          "report_text_F2_AI_1": msg,
          "max_tokens_F2_AI_1": 300,
        },
      );
      if(res.statusCode == 200){
      return DataSuccess(res.data);

      }else{
        return DataFailed("خطا");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> aiSubmitTextsEmotion({
    String? username,
    String? msg,
  }) async {
    try {
      final res = await ApiHelper.makePostForAi(
        path: "submit-TextsEmotion-F2_AI_2",
        body: {
          "user_name_F2_AI_2": username,
          "report_text_F2_AI_2": msg,
          "max_tokens_F2_AI_2": 300,
        },
      );
      return DataSuccess(res.data);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }
}

class AiImageModel {
  String? name;
  double? distance;
  String? emotion;
  dynamic score;

  AiImageModel({this.name, this.distance, this.emotion, this.score});

  factory AiImageModel.fromJson(Map<String, dynamic> json) => AiImageModel(
    name: json["Name"],
    distance: json["Distance"]?.toDouble(),
    emotion: json["Emotion"],
    score: json["Score"],
  );

  Map<String, dynamic> toJson() => {
    "Name": name,
    "Distance": distance,
    "Emotion": emotion,
    "Score": score,
  };
}
