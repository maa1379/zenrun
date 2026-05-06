class SettingModel {
  final int? id;
  final String? hazinehErsal;
  final String? appVersion;
  final bool? isForceUpdate;
  final int? taskToLvlUp;
  final String? helpUrl;
  final int? inviteCoin;
  final int? userToBoronzLvl;
  final int? userToSilverLvl;
  final int? userToGoldLvl;
  final int? userToVipLvl;
  final String? googlePlay;
  final String? appStore;
  final String? rCoin1;
  final String? rCoin2;
  final String? rCoin3;
  final String? rCoin4;
  final String? rCoin5;
  final String? rCoin6;
  final String? rCoin7;
  final String? rCoin8;
  final String? rCoin9;
  final String? rCoin10;
  // Subscription plan prices (in dollars)
  final String? eshterak1Mah;
  final String? eshterak3Mah;
  final String? eshterak6Mah;
  final String? eshterak12Mah;

  SettingModel({
    this.id,
    this.hazinehErsal,
    this.appVersion,
    this.isForceUpdate,
    this.taskToLvlUp,
    this.helpUrl,
    this.inviteCoin,
    this.userToBoronzLvl,
    this.userToSilverLvl,
    this.userToGoldLvl,
    this.userToVipLvl,
    this.googlePlay,
    this.appStore,
    this.rCoin1,
    this.rCoin2,
    this.rCoin3,
    this.rCoin4,
    this.rCoin5,
    this.rCoin6,
    this.rCoin7,
    this.rCoin8,
    this.rCoin9,
    this.rCoin10,
    this.eshterak1Mah,
    this.eshterak3Mah,
    this.eshterak6Mah,
    this.eshterak12Mah,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) => SettingModel(
    id: json["id"],
    hazinehErsal: json["hazinehErsal"],
    appVersion: json["appVersion"],
    isForceUpdate: json["isForceUpdate"],
    taskToLvlUp: json["taskToLvlUp"],
    helpUrl: json["helpURL"],
    inviteCoin: json["inviteCoin"],
    userToBoronzLvl: json["userToBoronzLvl"],
    userToSilverLvl: json["userToSilverLvl"],
    userToGoldLvl: json["userToGoldLvl"],
    userToVipLvl: json["userToVIPLvl"],
    googlePlay: json["GooglePlay"],
    appStore: json["AppStore"],
    rCoin1: json["RCoin1"],
    rCoin2: json["RCoin2"],
    rCoin3: json["RCoin3"],
    rCoin4: json["RCoin4"],
    rCoin5: json["RCoin5"],
    rCoin6: json["RCoin6"],
    rCoin7: json["RCoin7"],
    rCoin8: json["RCoin8"],
    rCoin9: json["RCoin9"],
    rCoin10: json["RCoin10"],
    eshterak1Mah: json["eshterak_1Mah"]?.toString(),
    eshterak3Mah: json["eshterak_3Mah"]?.toString(),
    eshterak6Mah: json["eshterak_6Mah"]?.toString(),
    eshterak12Mah: json["eshterak_12Mah"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "hazinehErsal": hazinehErsal,
    "appVersion": appVersion,
    "isForceUpdate": isForceUpdate,
    "taskToLvlUp": taskToLvlUp,
    "helpURL": helpUrl,
    "inviteCoin": inviteCoin,
    "userToBoronzLvl": userToBoronzLvl,
    "userToSilverLvl": userToSilverLvl,
    "userToGoldLvl": userToGoldLvl,
    "userToVIPLvl": userToVipLvl,
    "GooglePlay": googlePlay,
    "AppStore": appStore,
    "RCoin1": rCoin1,
    "RCoin2": rCoin2,
    "RCoin3": rCoin3,
    "RCoin4": rCoin4,
    "RCoin5": rCoin5,
    "RCoin6": rCoin6,
    "RCoin7": rCoin7,
    "RCoin8": rCoin8,
    "RCoin9": rCoin9,
    "RCoin10": rCoin10,
    "eshterak_1Mah": eshterak1Mah,
    "eshterak_3Mah": eshterak3Mah,
    "eshterak_6Mah": eshterak6Mah,
    "eshterak_12Mah": eshterak12Mah,
  };
}
