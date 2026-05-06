class TaskModel {
  final int? id;
  final dynamic fileUrl;
  final String? title;
  final String? type;
  final String? description;
  final String? videoUrlEn;
  final String? imageUrl;
  final String? audioUrlEn;
  final DateTime? date;
  final int? faslid;
  final int? tartib;
  final int? rCoin;
  final int? zCoin;
  final int? sCoin;
  final bool? isChalesh;
  final int? coin;
  final String? fileTime;
  final String? exampleUrl;
  final bool? isMamoriyat;
  final String? mamoriyatUrl;
  final int? twoUser;
  final int? multiUser;
  final bool? isActive;
  final String? videoUrlCh;
  final String? audioUrlCh;
  final String? videoUrlIn;
  final String? audioUrlIn;
  final String? videoUrlEs;
  final String? audioUrlEs;
  final String? videoUrlAr;
  final String? audioUrlAr;
  final String? videoUrlFr;
  final String? audioUrlFr;
  final String? videoUrlRu;
  final String? audioUrlRu;
  final String? videoUrlPo;
  final String? audioUrlPo;
  final String? videoUrlBg;
  final String? audioUrlBg;
  final String? videoUrlJp;
  final String? audioUrlJp;
  final String? videoUrlOd;
  final String? audioUrlOd;
  final String? videoUrlAn;
  final String? audioUrlAn;
  final String? videoUrlTr;
  final String? audioUrlTr;
  final String? videoUrlKo;
  final String? audioUrlKo;
  final String? videoUrlFa;
  final String? audioUrlFa;
  final String? youtubeFileUrl;
  final String? color;
  final String? priceWallet;
  final String? priceCoin;
  final bool? isDaily;
  final bool? isQuiz;
  final bool? isInvite;
  final int? inviteCount;

  TaskModel({
    this.id,
    this.fileUrl,
    this.type,
    this.title,
    this.description,
    this.videoUrlEn,
    this.imageUrl,
    this.audioUrlEn,
    this.date,
    this.faslid,
    this.tartib,
    this.rCoin,
    this.zCoin,
    this.sCoin,
    this.isChalesh,
    this.coin,
    this.fileTime,
    this.exampleUrl,
    this.isMamoriyat,
    this.mamoriyatUrl,
    this.twoUser,
    this.multiUser,
    this.isActive,
    this.videoUrlCh,
    this.audioUrlCh,
    this.videoUrlIn,
    this.audioUrlIn,
    this.videoUrlEs,
    this.audioUrlEs,
    this.videoUrlAr,
    this.audioUrlAr,
    this.videoUrlFr,
    this.audioUrlFr,
    this.videoUrlRu,
    this.audioUrlRu,
    this.videoUrlPo,
    this.audioUrlPo,
    this.videoUrlBg,
    this.audioUrlBg,
    this.videoUrlJp,
    this.audioUrlJp,
    this.videoUrlOd,
    this.audioUrlOd,
    this.videoUrlAn,
    this.audioUrlAn,
    this.videoUrlTr,
    this.audioUrlTr,
    this.videoUrlKo,
    this.audioUrlKo,
    this.videoUrlFa,
    this.audioUrlFa,
    this.youtubeFileUrl,
    this.color,
    this.priceWallet,
    this.priceCoin,
    this.isDaily,
    this.isQuiz,
    this.isInvite,
    this.inviteCount,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json["id"],
    fileUrl: json["fileURL"],
    title: json["title"],
    description: json["description"],
    videoUrlEn: json["videoURL_EN"],
    imageUrl: json["imageURL"],
    audioUrlEn: json["audioURL_EN"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    faslid: json["faslid"],
    type: json["type"],
    tartib: json["tartib"],
    rCoin: json["RCoin"],
    zCoin: json["ZCoin"],
    sCoin: json["SCoin"],
    isChalesh: json["isChalesh"],
    coin: json["Coin"],
    fileTime: json["fileTime"],
    exampleUrl: json["exampleURL"],
    isMamoriyat: json["isMamoriyat"],
    mamoriyatUrl: json["mamoriyatURL"],
    twoUser: json["twoUser"],
    multiUser: json["multiUser"],
    isActive: json["isActive"],
    videoUrlCh: json["videoURL_CH"],
    audioUrlCh: json["audioURL_CH"],
    videoUrlIn: json["videoURL_IN"],
    audioUrlIn: json["audioURL_IN"],
    videoUrlEs: json["videoURL_ES"],
    audioUrlEs: json["audioURL_ES"],
    videoUrlAr: json["videoURL_AR"],
    audioUrlAr: json["audioURL_AR"],
    videoUrlFr: json["videoURL_FR"],
    audioUrlFr: json["audioURL_FR"],
    videoUrlRu: json["videoURL_RU"],
    audioUrlRu: json["audioURL_RU"],
    videoUrlPo: json["videoURL_PO"],
    audioUrlPo: json["audioURL_PO"],
    videoUrlBg: json["videoURL_BG"],
    audioUrlBg: json["audioURL_BG"],
    videoUrlJp: json["videoURL_JP"],
    audioUrlJp: json["audioURL_JP"],
    videoUrlOd: json["videoURL_OD"],
    audioUrlOd: json["audioURL_OD"],
    videoUrlAn: json["videoURL_AN"],
    audioUrlAn: json["audioURL_AN"],
    videoUrlTr: json["videoURL_TR"],
    audioUrlTr: json["audioURL_TR"],
    videoUrlKo: json["videoURL_KO"],
    audioUrlKo: json["audioURL_KO"],
    videoUrlFa: json["videoURL_FA"],
    audioUrlFa: json["audioURL_FA"],
    youtubeFileUrl: json["youtubeFileURL"],
    color: json["color"],
    priceWallet: json["PriceWallet"],
    priceCoin: json["PriceCoin"],
    isDaily: json["isDaily"],
    isQuiz: json["isQuiz"],
    isInvite: json["isInvite"] ?? false,
    inviteCount: json["InviteCount"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "fileURL": fileUrl,
    "title": title,
    "description": description,
    "videoURL_EN": videoUrlEn,
    "imageURL": imageUrl,
    "audioURL_EN": audioUrlEn,
    "date": date?.toIso8601String(),
    "faslid": faslid,
    "tartib": tartib,
    "RCoin": rCoin,
    "ZCoin": zCoin,
    "SCoin": sCoin,
    "isChalesh": isChalesh,
    "type": type,
    "Coin": coin,
    "fileTime": fileTime,
    "exampleURL": exampleUrl,
    "isMamoriyat": isMamoriyat,
    "mamoriyatURL": mamoriyatUrl,
    "twoUser": twoUser,
    "multiUser": multiUser,
    "isActive": isActive,
    "videoURL_CH": videoUrlCh,
    "audioURL_CH": audioUrlCh,
    "videoURL_IN": videoUrlIn,
    "audioURL_IN": audioUrlIn,
    "videoURL_ES": videoUrlEs,
    "audioURL_ES": audioUrlEs,
    "videoURL_AR": videoUrlAr,
    "audioURL_AR": audioUrlAr,
    "videoURL_FR": videoUrlFr,
    "audioURL_FR": audioUrlFr,
    "videoURL_RU": videoUrlRu,
    "audioURL_RU": audioUrlRu,
    "videoURL_PO": videoUrlPo,
    "audioURL_PO": audioUrlPo,
    "videoURL_BG": videoUrlBg,
    "audioURL_BG": audioUrlBg,
    "videoURL_JP": videoUrlJp,
    "audioURL_JP": audioUrlJp,
    "videoURL_OD": videoUrlOd,
    "audioURL_OD": audioUrlOd,
    "videoURL_AN": videoUrlAn,
    "audioURL_AN": audioUrlAn,
    "videoURL_TR": videoUrlTr,
    "audioURL_TR": audioUrlTr,
    "videoURL_KO": videoUrlKo,
    "audioURL_KO": audioUrlKo,
    "videoURL_FA": videoUrlFa,
    "audioURL_FA": audioUrlFa,
    "youtubeFileURL": youtubeFileUrl,
    "color": color,
    "PriceWallet": priceWallet,
    "PriceCoin": priceCoin,
    "isDaily": isDaily,
    "isQuiz": isQuiz,
    "isInvite": isInvite,
    "InviteCount": inviteCount,
  };
}
