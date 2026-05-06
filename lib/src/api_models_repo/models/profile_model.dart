import 'package:flutter/cupertino.dart';

class ProfileModel {
  final int? id;
  final String? username;
  final String? verifyCode;
  final String? phone;
  final String? name;
  final String? family;
  final String? type;
  final bool? isActive;
  final int? coin;
  final int? wallet;
  final String? image;
  bool? isPrivate;
  final DateTime? lastLogin;
  final String? invitedByEmail;
  final int? rCoin;
  final int? zCoin;
  final int? sCoin;
  final String? email;
  final String? country;
  final String? city;
  final String? mantaghe;
  final String? language;
  final bool? isMaster;
  final bool? isDeleted;
  final int? lvl;
  final int? followingCount;
  int? followerCount;
  final int? postCount;
  final String? bio;
  final String? FCMToken;
  final DateTime? expireEshterak;

  bool get hasActiveSubscription =>
      expireEshterak != null && expireEshterak!.isAfter(DateTime.now());

  TextEditingController nameC = TextEditingController();
  TextEditingController usernameC = TextEditingController();
  TextEditingController phoneC = TextEditingController();
  TextEditingController emailC = TextEditingController();
  TextEditingController familyC = TextEditingController();
  TextEditingController imageC = TextEditingController();
  TextEditingController cityC = TextEditingController();
  TextEditingController countryC = TextEditingController();
  TextEditingController stateC = TextEditingController();
  TextEditingController languageC = TextEditingController();
  TextEditingController bioC = TextEditingController();

  ProfileModel({
    this.id,
    this.username,
    this.verifyCode,
    this.phone,
    this.name,
    this.family,
    this.type,
    this.isDeleted,
    this.isActive,
    this.coin,
    this.wallet,
    this.image,
    this.isPrivate,
    this.lastLogin,
    this.invitedByEmail,
    this.rCoin,
    this.zCoin,
    this.sCoin,
    this.email,
    this.country,
    this.city,
    this.mantaghe,
    this.language,
    this.isMaster,
    this.lvl,
    this.followingCount,
    this.followerCount,
    this.postCount,
    this.bio,
    this.FCMToken,
    this.expireEshterak,
  }) {
    nameC.clear();
    usernameC.clear();
    phoneC.clear();
    emailC.clear();
    familyC.clear();
    imageC.clear();
    cityC.clear();
    countryC.clear();
    stateC.clear();
    languageC.clear();
    bioC.clear();

    nameC.text = name ?? "";
    usernameC.text = username ?? "";
    phoneC.text = phone ?? "";
    emailC.text = email ?? "";
    familyC.text = family ?? "";
    imageC.text = image ?? "";
    cityC.text = city ?? "";
    countryC.text = country ?? "";
    stateC.text = mantaghe ?? "";
    languageC.text = language ?? "";
    bioC.text = bio ?? "";
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json["id"],
    username: json["username"],
    verifyCode: json["verifyCode"],
    phone: json["phone"],
    name: json["name"],
    family: json["family"],
    type: json["type"],
    isActive: json["isActive"],
    coin: json["Coin"],
    wallet: json["wallet"],
    image: json["image"],
    isDeleted: json["isDeleted"],
    isPrivate: json["isPrivate"],
    FCMToken: json["FCMToken"],
    lastLogin:
        json["lastLogin"] == null ? null : DateTime.parse(json["lastLogin"]),
    invitedByEmail: json["invitedByEmail"],
    rCoin: json["RCoin"],
    zCoin: json["ZCoin"],
    sCoin: json["SCoin"],
    email: json["email"],
    country: json["country"],
    city: json["city"],
    mantaghe: json["mantaghe"],
    language: json["language"],
    isMaster: json["isMaster"],
    lvl: json["lvl"],
    followingCount: json["followingCount"],
    followerCount: json["followerCount"],
    postCount: json["postCount"],
    bio: json["Bio"],
    expireEshterak: json["ExpireEshterak"] == null
        ? null
        : DateTime.tryParse(json["ExpireEshterak"].toString()),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
    "verifyCode": verifyCode,
    "phone": phone,
    "name": name,
    "isDeleted": isDeleted,
    "family": family,
    "type": type,
    "isActive": isActive,
    "Coin": coin,
    "FCMToken": FCMToken,
    "wallet": wallet,
    "image": image,
    "isPrivate": isPrivate,
    "lastLogin": lastLogin?.toIso8601String(),
    "invitedByEmail": invitedByEmail,
    "RCoin": rCoin,
    "ZCoin": zCoin,
    "SCoin": sCoin,
    "email": email,
    "country": country,
    "city": city,
    "mantaghe": mantaghe,
    "language": language,
    "isMaster": isMaster,
    "lvl": lvl,
    "followingCount": followingCount,
    "followerCount": followerCount,
    "postCount": postCount,
    "Bio": bio,
    "ExpireEshterak": expireEshterak?.toIso8601String(),
  };
}
