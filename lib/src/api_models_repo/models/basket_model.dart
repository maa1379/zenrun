import 'dart:convert';

import 'package:zenrun/src/api_models_repo/models/product_model.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';

class BasketModel {
  final int? id;
  final String? email;
  final bool? isPaid;
  final DateTime? date;
  final String? takhfifCode;
  final bool? isTakhfif;
  final String? totalPrice;
  final String? totalPriceTakhfif;
  final String? description;
  final String? status;
  final bool? isDelivered;
  final dynamic transactionId;
  final String? shippingAmount;
  List<BasketDetailModel> productList = [];

  BasketModel({
    this.id,
    this.email,
    this.isPaid,
    this.date,
    this.takhfifCode,
    this.isTakhfif,
    this.totalPrice,
    this.totalPriceTakhfif,
    this.description,
    this.status,
    this.isDelivered,
    this.transactionId,
    this.shippingAmount,
  });

  static Future<void> saveToDB(List<ProductModel> item) async {
    await PrefHelpers.setCartModelDb(item);
  }

  static Future<List<ProductModel>> getDB() async {
    List<String> jsonStringList = await PrefHelpers.getCartModelDb() ?? [];
    if (jsonStringList.isEmpty) {
      return [];
    } else {
      final data = jsonStringList
          .map((jsonString) => ProductModel.fromJson(jsonDecode(jsonString)))
          .toList();
      return data;
    }
  }

  factory BasketModel.fromJson(Map<String, dynamic> json) => BasketModel(
    id: json["id"],
    email: json["Email"],
    isPaid: json["isPaid"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    takhfifCode: json["takhfifCode"],
    isTakhfif: json["isTakhfif"],
    totalPrice: json["totalPrice"],
    totalPriceTakhfif: json["totalPriceTakhfif"],
    description: json["description"],
    status: json["status"],
    isDelivered: json["isDelivered"],
    transactionId: json["transactionId"],
    shippingAmount: json["shippingAmount"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "Email": email,
    "isPaid": isPaid,
    "date": date?.toIso8601String(),
    "takhfifCode": takhfifCode,
    "isTakhfif": isTakhfif,
    "totalPrice": totalPrice,
    "totalPriceTakhfif": totalPriceTakhfif,
    "description": description,
    "status": status,
    "isDelivered": isDelivered,
    "transactionId": transactionId,
    "shippingAmount": shippingAmount,
  };
}


class BasketDetailModel {
  final int? id;
  final int? basketId;
  final String? email;
  final int? productId;
  final int? count;
  final String? price;
  final String? priceTakhfif;
  final String? totalPrice;
  final String? totalPriceTakhfif;
  final String? description;
  final String? productTitle;
  final int? subCategoryId;
  final String? subCategoryTitle;
  final int? categoryId;
  final String? categoryTitle;
  final DateTime? date;
  final bool? isCoin;
  final int? coinValue;
  final String? fileUrlEn;
  final bool? isRCoin;
  final int? rCoinValue;
  final bool? isZCoin;
  final int? zCoinValue;
  final bool? isSCoin;
  final int? sCoinValue;
  final String? fileTime;
  final dynamic fileUrlCh;
  final dynamic fileUrlIn;
  final dynamic fileUrlEs;
  final dynamic fileUrlAr;
  final dynamic fileUrlFr;
  final dynamic fileUrlRu;
  final dynamic fileUrlPo;
  final dynamic fileUrlBg;
  final dynamic fileUrlJp;
  final dynamic fileUrlOd;
  final dynamic fileUrlAn;
  final dynamic fileUrlTr;
  final dynamic fileUrlKo;
  final dynamic fileUrlFa;
  final String? youtubeFileUrl;

  BasketDetailModel({
    this.id,
    this.basketId,
    this.email,
    this.productId,
    this.count,
    this.price,
    this.priceTakhfif,
    this.totalPrice,
    this.totalPriceTakhfif,
    this.description,
    this.productTitle,
    this.subCategoryId,
    this.subCategoryTitle,
    this.categoryId,
    this.categoryTitle,
    this.date,
    this.isCoin,
    this.coinValue,
    this.fileUrlEn,
    this.isRCoin,
    this.rCoinValue,
    this.isZCoin,
    this.zCoinValue,
    this.isSCoin,
    this.sCoinValue,
    this.fileTime,
    this.fileUrlCh,
    this.fileUrlIn,
    this.fileUrlEs,
    this.fileUrlAr,
    this.fileUrlFr,
    this.fileUrlRu,
    this.fileUrlPo,
    this.fileUrlBg,
    this.fileUrlJp,
    this.fileUrlOd,
    this.fileUrlAn,
    this.fileUrlTr,
    this.fileUrlKo,
    this.fileUrlFa,
    this.youtubeFileUrl,
  });


  bool checkIsDiscount() {
    return priceTakhfif != price;
  }


  factory BasketDetailModel.fromJson(Map<String, dynamic> json) => BasketDetailModel(
    id: json["id"],
    basketId: json["basketId"],
    email: json["Email"],
    productId: json["productId"],
    count: json["count"],
    price: json["price"],
    priceTakhfif: json["priceTakhfif"],
    totalPrice: json["totalPrice"],
    totalPriceTakhfif: json["totalPriceTakhfif"],
    description: json["description"],
    productTitle: json["productTitle"],
    subCategoryId: json["subCategoryId"],
    subCategoryTitle: json["subCategoryTitle"],
    categoryId: json["categoryId"],
    categoryTitle: json["categoryTitle"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    isCoin: json["isCoin"],
    coinValue: json["CoinValue"],
    fileUrlEn: json["fileURL_EN"],
    isRCoin: json["isRCoin"],
    rCoinValue: json["RCoinValue"],
    isZCoin: json["isZCoin"],
    zCoinValue: json["ZCoinValue"],
    isSCoin: json["isSCoin"],
    sCoinValue: json["SCoinValue"],
    fileTime: json["fileTime"],
    fileUrlCh: json["fileURL_CH"],
    fileUrlIn: json["fileURL_IN"],
    fileUrlEs: json["fileURL_ES"],
    fileUrlAr: json["fileURL_AR"],
    fileUrlFr: json["fileURL_FR"],
    fileUrlRu: json["fileURL_RU"],
    fileUrlPo: json["fileURL_PO"],
    fileUrlBg: json["fileURL_BG"],
    fileUrlJp: json["fileURL_JP"],
    fileUrlOd: json["fileURL_OD"],
    fileUrlAn: json["fileURL_AN"],
    fileUrlTr: json["fileURL_TR"],
    fileUrlKo: json["fileURL_KO"],
    fileUrlFa: json["fileURL_FA"],
    youtubeFileUrl: json["youtubeFileURL"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "basketId": basketId,
    "Email": email,
    "productId": productId,
    "count": count,
    "price": price,
    "priceTakhfif": priceTakhfif,
    "totalPrice": totalPrice,
    "totalPriceTakhfif": totalPriceTakhfif,
    "description": description,
    "productTitle": productTitle,
    "subCategoryId": subCategoryId,
    "subCategoryTitle": subCategoryTitle,
    "categoryId": categoryId,
    "categoryTitle": categoryTitle,
    "date": date?.toIso8601String(),
    "isCoin": isCoin,
    "CoinValue": coinValue,
    "fileURL_EN": fileUrlEn,
    "isRCoin": isRCoin,
    "RCoinValue": rCoinValue,
    "isZCoin": isZCoin,
    "ZCoinValue": zCoinValue,
    "isSCoin": isSCoin,
    "SCoinValue": sCoinValue,
    "fileTime": fileTime,
    "fileURL_CH": fileUrlCh,
    "fileURL_IN": fileUrlIn,
    "fileURL_ES": fileUrlEs,
    "fileURL_AR": fileUrlAr,
    "fileURL_FR": fileUrlFr,
    "fileURL_RU": fileUrlRu,
    "fileURL_PO": fileUrlPo,
    "fileURL_BG": fileUrlBg,
    "fileURL_JP": fileUrlJp,
    "fileURL_OD": fileUrlOd,
    "fileURL_AN": fileUrlAn,
    "fileURL_TR": fileUrlTr,
    "fileURL_KO": fileUrlKo,
    "fileURL_FA": fileUrlFa,
    "youtubeFileURL": youtubeFileUrl,
  };
}
