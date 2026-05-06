import 'package:zenrun/src/api_models_repo/models/product_model.dart';
import 'package:zenrun/src/api_models_repo/models/quiz_model.dart';
import 'package:zenrun/src/api_models_repo/models/shop_product_model.dart';

import '../../core/PrefHelper/PrefHelpers.dart';
import '../../core/network/DataState.dart';
import '../../core/network/api_helper.dart';
import 'models/basket_model.dart';
import 'models/category_model.dart';
import 'models/circle_model.dart';
import 'models/comment_model.dart';
import 'models/contact_us_model.dart';
import 'models/fasl_model.dart';
import 'models/follow_model.dart';
import 'models/like_model.dart';
import 'models/message_model.dart';
import 'models/notif_model.dart';
import 'models/post_model.dart';
import 'models/profile_model.dart';
import 'models/setting_model.dart';
import 'models/shop_history_model.dart';
import 'models/slider_model.dart';
import 'models/story_model.dart';
import 'models/tag_model.dart';
import 'models/task_model.dart';
import 'models/user_task_model.dart';

class ApiService {
  ApiService._();

  static ApiService get instance => ApiService._();

  Future<DataState<String>> sendSms({
    String? email,
    String? phone,
    String? city,
    String? country,
    String? language,
    String? state,
    String? invitedEmail,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Register.aspx",
        queryParameters: {
          "email": email?.toLowerCase(),
          "phone": phone,
          "city": city,
          "country": country,
          "language": language,
          "mantaghe": state,
          "invitedEmail": invitedEmail,
        },
      );
      if(!res.data.toString().startsWith("-")){
      return DataSuccess(res.data);
      }else{
        return DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> login({String? email}) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Login.aspx",
        queryParameters: {"email": email},
      );
      if (res.data.toString().startsWith("1")) {
        return DataSuccess(res.data);
      } else {
        return DataFailed("error");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<bool> checkUsername({String? username}) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "CheckUsername.aspx",
        queryParameters: {"username": username},
      );
      if (res.data.toString().startsWith("1")) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<DataState<String>> setBasket({
    required String discountedPrice,
    required String basketPrice,
    required String discountedCode,
    required String isDiscounted,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetBasket.aspx",
        queryParameters: {
          "Email": await PrefHelpers.getUser(),
          "Discountedprice": discountedPrice,
          "basketPrice": basketPrice,
          "description": "خرید اشتراک",
          "discountedCode": discountedCode,
          "isDelivered": "false",
          "isPaid": "false",
          "isdiscounted": isDiscounted,
          "shippingAmount": "0",
          "status": "وضعیت سفارش",
        },
      );
      return DataSuccess(res.data.toString());
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setBasketDetail({
    required String basketID,
    required String productID,
    required String count,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetBasketDetail.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "basketID": basketID,
          "productID": productID,
          "count": count,
          "description": "Buy",
        },
      );
      return DataSuccess(res.data.toString());
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setUserShopProduct({
    required String id,
    required String productID,
    required String isPaid,
    required String expireDate,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetUserShopProduct.aspx",
        queryParameters: {
          "id": id,
          "email": await PrefHelpers.getUser(),
          "date": DateTime.now(),
          "ExpireDate": expireDate,
          "ShopId": productID,
          "isPaid": isPaid,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setTag({
    required String friendEmail,
    required String description,
    required bool isTask,
    required String circleId,
    required String taskId,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetTag.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "friendEmail": friendEmail,
          "type": isTask ? "task" : "social",
          "description": description,
          "isRead": "false",
          "circleId": isTask ? "0" : circleId,
          "taskId": isTask ? taskId : "0",
          "date": DateTime.now().toIso8601String(),
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setBasketTruePay({required String basketID}) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "PayBasket.aspx",
        queryParameters: {"basketID": basketID},
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> verifyDiscount(String code) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "VerifyTakhfif.aspx",
        queryParameters: {"code": code},
      );
      if (res.statusCode == 200 &&
          res.data != null &&
          res.data[0]['isActive'] == true) {
        if (res.data[0]['darsad'].toString() != "0" &&
            res.data[0]['mablagh'] != "0") {
          return DataSuccess('${res.data[0]['darsad']}');
        } else {
          return DataSuccess('${res.data[0]['mablagh']}');
        }
      } else {
        return const DataFailed(
          "The discount code is incorrect or has expired.",
        );
      }
    } catch (e) {
      return const DataFailed("The discount code is incorrect or has expired.");
    }
  }

  Future<DataState<String>> verifyOtp(String email, String otp) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "VerifyEmailCode.aspx",
        queryParameters: {"email": email, "verifyCode": otp},
      );
      return DataSuccess(res.data);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<ProfileModel>> getProfile({String? email}) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "UserDetailNew.aspx",
        queryParameters: {"email": email ?? await PrefHelpers.getUser()},
      );
      return DataSuccess(ProfileModel.fromJson(res.data[0]));
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<ProfileModel>>> getAllProfile() async {
    List<ProfileModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(path: "UserDetailNew.aspx");

      for (var i in res.data) {
        list.add(ProfileModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<SliderModel>>> getSliders() async {
    List<SliderModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(path: "Slider.aspx");

      for (var i in res.data) {
        list.add(SliderModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<PostModel>>> getPosts(String email) async {
    List<PostModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Post.aspx",
        queryParameters: (email == await PrefHelpers.getUser())
            ? {"emailForMyPost": email}
            : {"email": email},
      );

      for (var i in res.data) {
        list.add(PostModel.fromJson(i));
      }
      // list.removeWhere((p) => p.isReels == true && (p.video == "error" || p.video == null || p.video == ""));
      // list.removeWhere((p) => p.image1 == "error" || p.image1 == null || p.image1 == "",);
      return DataSuccess(list.reversed.toList());
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<PostModel>>> getRandomPost() async {
    List<PostModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Post.aspx",
        queryParameters: {},
      );

      for (var i in res.data) {
        list.add(PostModel.fromJson(i));
      }
      list.removeWhere((p) => p.isReels == true && (p.video == "error" || p.video == null || p.video == ""));
      list.removeWhere((p) => p.image1 == "error" || p.image1 == null || p.image1 == "",);
      return DataSuccess(list.reversed.toList());
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<PostModel>?> getOnePost(String id) async {
    List<PostModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Post.aspx",
        queryParameters: {"id": id},
      );

      for (var i in res.data) {
        list.add(PostModel.fromJson(i));
      }
      // list.removeWhere((p) => p.isReels == true && (p.video == "error" || p.video == null || p.video == ""));
      // list.removeWhere((p) => p.image1 == "error" || p.image1 == null || p.image1 == "",);
      if (list.isNotEmpty) {
        return DataSuccess(list.first);
      } else {
        return null;
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<PostModel>>> getOtherUserPosts(
    String emailForOtherPost,
  ) async {
    List<PostModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Post.aspx",
        queryParameters: emailForOtherPost == await PrefHelpers.getUser()?{
          "emailForMyPost": await PrefHelpers.getUser(),
        }:{
          "emailForOtherPost": emailForOtherPost,
          "email": await PrefHelpers.getUser(),
        },
      );

      for (var i in res.data) {
        list.add(PostModel.fromJson(i));
      }
      // list.removeWhere((p) => p.isReels == true && (p.video == "error" || p.video == null || p.video == ""));
      // list.removeWhere((p) => p.image1 == "error" || p.image1 == null || p.image1 == "",);
      return DataSuccess(list.reversed.toList());
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setProfile({
    String? Bio,
    String? Coin,
    String? RCoin,
    String? SCoin,
    String? ZCoin,
    String? city,
    String? country,
    String? email,
    String? family,
    String? followerCount,
    String? followingCount,
    String? image,
    String? isActive,
    String? isMaster,
    String? isPrivate,
    String? language,
    String? lvl,
    String? mantaghe,
    String? name,
    String? phone,
    String? postCount,
    String? type,
    String? username,
    String? wallet,
    String? fcm,
    String? expireEshterak,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetProfile.aspx",
        queryParameters: {
          "Bio": Bio,
          "Coin": Coin,
          "RCoin": RCoin,
          "SCoin": SCoin,
          "ZCoin": ZCoin,
          "city": city,
          "country": country,
          "email": email,
          "family": family,
          "followerCount": followerCount,
          "followingCount": followingCount,
          "image": image,
          "isActive": isActive,
          "isMaster": isMaster,
          "isPrivate": isPrivate,
          "language": language,
          "lvl": lvl,
          "mantaghe": mantaghe,
          "name": name,
          "phone": phone,
          "postCount": postCount,
          "type": type,
          "username": username,
          "wallet": wallet,
          "FCMToken": fcm,
          "ExpireEshterak": expireEshterak,
        },
      );
      return DataSuccess(res.data.toString());
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setPostOrReels({
    String? description,
    String? id,
    String? image1,
    String? image2,
    String? image3,
    String? image4,
    String? image5,
    String? isAccept,
    String? isLikeToCoin,
    String? isReels,
    String? label,
    String? userImage,
    String? video,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetPost.aspx",
        queryParameters: {
          "date": DateTime.now().toIso8601String(),
          "email": await PrefHelpers.getUser(),
          "id": id ?? "0",
          "description": description,
          "image1": image1,
          "image2": image2,
          "image3": image3,
          "image4": image4,
          "image5": image5,
          "isAccept": isAccept,
          "isLikeToCoin": isLikeToCoin,
          "isReels": isReels,
          "label": label,
          "labelColor": "black",
          "userImage": userImage,
          "video": video,
        },
      );
      if (res.data.toString().startsWith("1") == true) {
        return DataSuccess(res.data.toString());
      } else {
        return DataFailed("error");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setLikeApi(String postId) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetLike.aspx",
        queryParameters: {
          "Email": await PrefHelpers.getUser(),
          "postId": postId,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setCoinToPost(String postId, String amount) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetCoinToPost.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "PostId": postId,
          "amount": amount,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setFollow({
    required String followEmail,
    required String circleId,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetFollow.aspx",
        queryParameters: {
          "Email": await PrefHelpers.getUser(),
          "FollowEmail": followEmail,
          "circleId": circleId,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> acceptFollow({required String id}) async {
      final res = await ApiHelper.makeGetRequest(
        path: "AcceptFollow.aspx",
        queryParameters: {"id": id},
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    try {
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> deleteNotif({required String id}) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "DeleteNotif.aspx",
        queryParameters: {"id": id},
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> deleteFollow({required String id}) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "DeleteFollow.aspx",
        queryParameters: {"id": id},
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setCoinToWallet(String coin) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetCoinToWallet.aspx",
        queryParameters: {"email": await PrefHelpers.getUser(), "Coin": coin},
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setLikeToCoin(String postId) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetLikeToCoin.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "PostId": postId,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setCoinToCoin(String amount, String type) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetCoinToCoin.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "amount": amount,
          "type": type,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setWalletToCoin(String coin) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetWalletToCoin.aspx",
        queryParameters: {"email": await PrefHelpers.getUser(), "Amount": coin},
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setWallet(String amount) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetWallet.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "amount": amount,
        },
      );
      if (res.statusCode == 200 && !res.data.toString().startsWith("-")) {
        return DataSuccess(res.data.toString());
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setStory(String url) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetStory.aspx",
        queryParameters: {"email": await PrefHelpers.getUser(), "fileURL": url},
      );
      if (res.statusCode == 200 && !res.data.toString().startsWith("-")) {
        return DataSuccess(res.data.toString());
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> deleteStory(String id) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "DeleteStory.aspx",
        queryParameters: {"id": id},
      );
      if (res.statusCode == 200 && !res.data.toString().startsWith("-")) {
        return DataSuccess(res.data.toString());
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> deletePost(String id) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "DeletePost.aspx",
        queryParameters: {"id": id},
      );
      if (res.statusCode == 200 && !res.data.toString().startsWith("-")) {
        return DataSuccess(res.data.toString());
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setCommentApi({
    required String id,
    required String postId,
    required String comment,
    required String userFamily,
    required String userName,
    required String userImage,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetComment.aspx",
        queryParameters: {
          "id":id ?? "0",
          "email": await PrefHelpers.getUser(),
          "date": DateTime.now().toIso8601String(),
          "postId": postId,
          "comment": comment,
          "userFamily": userFamily,
          "userName": userName,
          "userImage": userImage,
          "userImage": userImage,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setUserTask({
    required String id,
    required String taskId,
    required String? fileURL,
    required String isLevelUpDone,
    required String userCount,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetUserTask.aspx",
        queryParameters: {
          "id": id,
          "email": await PrefHelpers.getUser(),
          "date": DateTime.now().toIso8601String(),
          "taskId": taskId,
          "isLevelUpDone": isLevelUpDone,
          "userCount": userCount,
          "fileURL": fileURL,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setAddCoin({
    required String coin,
    required String RCoin,
    required String ZCoin,
    required String SCoin,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetAddCoin.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "Coin": coin,
          "RCoin": RCoin,
          "ZCoin": ZCoin,
          "SCoin": SCoin,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setSubCoin({
    required String coin,
    required String RCoin,
    required String ZCoin,
    required String SCoin,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetSubCoin.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "Coin": coin,
          "RCoin": RCoin,
          "ZCoin": ZCoin,
          "SCoin": SCoin,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setAnswer({
    required String questionId,
    required String quizId,
    required String gozineEntekhabi,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetJavab.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "questionId": questionId,
          "quizId": quizId,
          "gozineEntekhabi": gozineEntekhabi,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> startQuiz({required String quizId}) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "StartQuiz.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "QuizId": quizId,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> finishQuiz({required String quizId}) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "FinishQuiz.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "QuizId": quizId,
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<CommentModel>>> getCommentListApi(String postId) async {
    List<CommentModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Comment.aspx",
        queryParameters: {"postId": postId},
      );
      list.clear();
      for (var i in res.data) {
        list.add(CommentModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> deleteCommentApi(String id) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "DeleteComment.aspx",
        queryParameters: {"id": id},
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> deleteLikeApi(String id) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "DeleteLike.aspx",
        queryParameters: {"id": id},
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<LikeModel>>> getLikeListApi(String postId) async {
    List<LikeModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Like.aspx",
        queryParameters: {"postId": postId},
      );
      list.clear();
      for (var i in res.data) {
        list.add(LikeModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<StoryModel>>> getStoryList({String? myEmail}) async {
    List<StoryModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "ListStory.aspx",
        queryParameters: myEmail == null
            ? {"email": (await PrefHelpers.getUser()).toString().toLowerCase()}
            : {"myemail": myEmail.toString().toLowerCase()},
      );
      list.clear();
      for (var i in res.data) {
        list.add(StoryModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<FaslModel>>> getFaslList() async {
    List<FaslModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Fasl.aspx",
        queryParameters: {},
      );
      list.clear();
      for (var i in res.data) {
        list.add(FaslModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<TaskModel>>> getTaskList() async {
    List<TaskModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Task.aspx",
        queryParameters: {},
      );
      list.clear();
      for (var i in res.data) {
        list.add(TaskModel.fromJson(i));
      }
      list.sort((a, b) {
        return a.date!.compareTo(b.date!);
      });
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<QuizModel>>> getQuizList() async {
    List<QuizModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Quiz.aspx",
        queryParameters: {},
      );
      list.clear();
      for (var i in res.data) {
        list.add(QuizModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<UserQuizModel>>> getUserQuizList() async {
    List<UserQuizModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "UserQuiz.aspx",
        queryParameters: {},
      );
      list.clear();
      for (var i in res.data) {
        list.add(UserQuizModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<QuestionModel>>> getQuestionList(String quizId) async {
    List<QuestionModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "ListSoal.aspx",
        queryParameters: {"quizId": quizId},
      );
      list.clear();
      for (var i in res.data) {
        list.add(QuestionModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<UserTaskModel>>> getUserTaskList() async {
    List<UserTaskModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "UserTask.aspx",
        queryParameters: {"email": await PrefHelpers.getUser()},
      );
      list.clear();
      for (var i in res.data) {
        list.add(UserTaskModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<ProductModel>>> getAllProducts() async {
    List<ProductModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Product.aspx",
        queryParameters: {},
      );
      list.clear();
      for (var i in res.data) {
        list.add(ProductModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<ProductModel>>> getOnProductById(id) async {
    List<ProductModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Product.aspx",
        queryParameters: {"id": id},
      );
      list.clear();
      for (var i in res.data) {
        list.add(ProductModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<ShopHistoryModel>>> getUserShopHistoryList() async {
    List<ShopHistoryModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "UserShopHistory.aspx",
        queryParameters: {"email": await PrefHelpers.getUser()},
      );
      list.clear();
      for (var i in res.data) {
        list.add(ShopHistoryModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<CircleModel>>> getUserCircleList({
    String? email,
  }) async {
    List<CircleModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Circle.aspx",
        queryParameters: {"email": email ?? await PrefHelpers.getUser()},
      );
      list.clear();
      for (var i in res.data) {
        list.add(CircleModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<FollowModel>>> getFollowList({
    String? email,
  }) async {
    List<FollowModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Follow.aspx",
        queryParameters: {"Email": email},
      );
      list.clear();
      for (var i in res.data) {
        list.add(FollowModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }


  Future<DataState<ContactUsModel>> getContactUs() async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "ContactUs.aspx",
        queryParameters: {},
      );
      return DataSuccess(ContactUsModel.fromJson(res.data[0]));
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<SettingModel>> getSetting() async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Setting.aspx",
        queryParameters: {},
      );
      return DataSuccess(SettingModel.fromJson(res.data[0]));
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> setEshterak({
    required String expireDate,
    required String months,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SetEshterak.aspx",
        queryParameters: {
          "email": await PrefHelpers.getUser(),
          "ExpireEshterak": expireDate,
          "months": months,
          "date": DateTime.now().toIso8601String(),
        },
      );
      if (res.statusCode == 200 && res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("e");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<FollowModel>>> getFollowList2({
    String? followEmail,
  }) async {
    List<FollowModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Follow.aspx",
        queryParameters: {"FollowEmail": followEmail},
      );
      list.clear();
      for (var i in res.data) {
        list.add(FollowModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<TagModel>>> getTagList() async {
    List<TagModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Tag.aspx",
        queryParameters: {"email": await PrefHelpers.getUser()},
      );
      list.clear();
      for (var i in res.data) {
        list.add(TagModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<NotifModel>>> getNotifList() async {
    List<NotifModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Notif.aspx",
        queryParameters: {"receiverEmail": await PrefHelpers.getUser()},
      );
      list.clear();
      for (var i in res.data) {
        list.add(NotifModel.fromJson(i));
      }
      return DataSuccess(list.reversed.toList());
    } catch (e) {
      return DataFailed(e.toString());
    }
  }


  Future<DataState<List<CategoryModel>>> getAllCategory() async {
    List<CategoryModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "Category.aspx",
        queryParameters: {},
      );
      list.clear();
      for (var i in res.data) {
        print(i['image']);
        list.add(CategoryModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<ShopProductModel>>> getAllShopProduct() async {
    List<ShopProductModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "ShopProduct.aspx",
        queryParameters: {},
      );
      list.clear();
      for (var i in res.data) {
        list.add(ShopProductModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<SubCategoryModel>>> getAllSubCategory(
    String categoryId,
  ) async {
    List<SubCategoryModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "SubCategory.aspx",
        queryParameters: {"categoryID": categoryId},
      );
      list.clear();
      for (var i in res.data) {
        list.add(SubCategoryModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<BasketModel>>> getBasketListApi() async {
    List<BasketModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "BasketHistory.aspx",
        queryParameters: {"email": await PrefHelpers.getUser()},
      );
      list.clear();
      for (var i in res.data) {
        list.add(BasketModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<BasketDetailModel>>> basketHistoryListApi(
    String basketID,
  ) async {
    List<BasketDetailModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "BasketDetailHistory.aspx",
        queryParameters: {"basketID": basketID},
      );
      list.clear();
      for (var i in res.data) {
        list.add(BasketDetailModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  // Future<DataState<List<ChatModel>>> getChatListApi(String phone) async {
  //   try {
  //     List<ChatModel> list = [];
  //     final res = await ApiHelper.makeGetRequest(
  //       path: "chat/ListChat.aspx",
  //       queryParameters: {"user_Email": await PrefHelpers.getUser()},
  //     );
  //     list.clear();
  //     for (var i in res.data) {
  //       list.add(ChatModel.fromJson(i));
  //     }
  //     return DataSuccess(list);
  //   } catch (e) {
  //     return DataFailed(e.toString());
  //   }
  // }

  Future<DataState<List<MessageModel>>> getMessageListApi(
    String userReceiver,
  ) async {
    List<MessageModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "chat/ListMessage.aspx",
        queryParameters: {
          "user_Email": await PrefHelpers.getUser(),
          "receiver_Email": userReceiver,
        },
      );
      list.clear();
      for (var i in res.data) {
        list.add(MessageModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> sendMessageApi({
    String? link,
    String? message,
    String? receiverPhone,
    String? type,
    String? userPhone,
  }) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "chat/SendMessage.aspx",
        queryParameters: {
          "link": link,
          "message": message,
          "receiver_email": receiverPhone,
          "type": type,
          "user_email": await PrefHelpers.getUser(),
        },
      );
      if (res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("error");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> readMessageApi(String chatId) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "chat/ReadMessage.aspx",
        queryParameters: {"chat_id": chatId},
      );
      if (res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("error");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> readAllMessageApi(String chatId) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "chat/SetReadAllMessage.aspx",
        queryParameters: {"chat_id": chatId},
      );
      if (res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("error");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> pinChatApi(String chatId) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "chat/PinChat.aspx",
        queryParameters: {"chat_id": chatId},
      );
      if (res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("error");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> unPinChatApi(String chatId) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "chat/UnPinChat.aspx",
        queryParameters: {"chat_id": chatId},
      );
      if (res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("error");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<String>> deleteMessageApi(String messageId) async {
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "chat/DeleteMessage.aspx",
        queryParameters: {"message_id": messageId},
      );
      if (res.data.toString().startsWith("1")) {
        return const DataSuccess("ok");
      } else {
        return const DataFailed("error");
      }
    } catch (e) {
      return DataFailed(e.toString());
    }
  }

  Future<DataState<List<ProfileModel>>> getUsersListApi() async {
    List<ProfileModel> list = [];
    try {
      final res = await ApiHelper.makeGetRequest(
        path: "chat/ListUsers.aspx",
        queryParameters: {"user_Email": await PrefHelpers.getUser()},
      );
      list.clear();
      for (var i in res.data) {
        list.add(ProfileModel.fromJson(i));
      }
      return DataSuccess(list);
    } catch (e) {
      return DataFailed(e.toString());
    }
  }
}
