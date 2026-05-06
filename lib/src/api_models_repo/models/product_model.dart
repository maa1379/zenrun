class ProductModel {
  final int? id;
  final String? title;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? description;
  final String? price;
  final String? priceTakhfif;
  final bool? isActive;
  final int? inventory;
  final int? categoryId;
  final String? categoryTitle;
  final int? subCategoryId;
  final String? subCategoryTitle;
  final bool? isSpecial;
  final bool? isTop;
  final int? tartib;
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
  final String? fileUrlCh;
  final String? fileUrlIn;
  final String? fileUrlEs;
  final String? fileUrlAr;
  final String? fileUrlFr;
  final String? fileUrlRu;
  final String? fileUrlPo;
  final String? fileUrlBg;
  final String? fileUrlJp;
  final String? fileUrlOd;
  final String? fileUrlAn;
  final String? fileUrlTr;
  final String? fileUrlKo;
  final String? fileUrlFa;
  final String? youtubeFileUrl;
  List<String> images = [];

  bool checkIsDiscount() {
    return priceTakhfif != price;
  }

  ProductModel({
    this.id,
    this.title,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.description,
    this.price,
    this.priceTakhfif,
    this.isActive,
    this.inventory,
    this.categoryId,
    this.categoryTitle,
    this.subCategoryId,
    this.subCategoryTitle,
    this.isSpecial,
    this.isTop,
    this.tartib,
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
  }){
    if(image1 != null || image1 != ""){
      images.add(image1 ?? "");
    }
    if(image2 != null || image2 != ""){
      images.add(image2 ?? "");
    }
    if(image3 != null || image3 != ""){
      images.add(image3 ?? "");
    }
    if(image4 != null  || image4 != ""){
      images.add(image4 ?? "");
    }
    if(image5 != null || image5 != ""){
      images.add(image5 ?? "");
    }
  }

  ProductModel copy() {
    return ProductModel(
      id: id,
      title: title,
      image1: image1,
      image2: image2,
      image3: image3,
      image4: image4,
      image5: image5,
      description: description,
      price: price,
      priceTakhfif: priceTakhfif,
      isActive: isActive,
      inventory: inventory,
      categoryId: categoryId,
      categoryTitle: categoryTitle,
      subCategoryId: subCategoryId,
      subCategoryTitle: subCategoryTitle,
      isSpecial: isSpecial,
      isTop: isTop,
      tartib: tartib,
      isCoin: isCoin,
      coinValue: coinValue,
      fileUrlEn: fileUrlEn,
      isRCoin: isRCoin,
      rCoinValue: rCoinValue,
      isZCoin: isZCoin,
      zCoinValue: zCoinValue,
      isSCoin: isSCoin,
      sCoinValue: sCoinValue,
      fileTime: fileTime,
      fileUrlCh: fileUrlCh,
      fileUrlIn: fileUrlIn,
      fileUrlEs: fileUrlEs,
      fileUrlAr: fileUrlAr,
      fileUrlFr: fileUrlFr,
      fileUrlRu: fileUrlRu,
      fileUrlPo: fileUrlPo,
      fileUrlBg: fileUrlBg,
      fileUrlJp: fileUrlJp,
      fileUrlOd: fileUrlOd,
      fileUrlAn: fileUrlAn,
      fileUrlTr: fileUrlTr,
      fileUrlKo: fileUrlKo,
      fileUrlFa: fileUrlFa,
      youtubeFileUrl: youtubeFileUrl,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json["id"],
    title: json["title"],
    image1: json["image1"],
    image2: json["image2"],
    image3: json["image3"],
    image4: json["image4"],
    image5: json["image5"],
    description: json["description"],
    price: json["price"],
    priceTakhfif: json["priceTakhfif"],
    isActive: json["isActive"],
    inventory: json["inventory"],
    categoryId: json["categoryId"],
    categoryTitle: json["categoryTitle"],
    subCategoryId: json["subCategoryId"],
    subCategoryTitle: json["subCategoryTitle"],
    isSpecial: json["isSpecial"],
    isTop: json["isTop"],
    tartib: json["tartib"],
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
    "title": title,
    "image1": image1,
    "image2": image2,
    "image3": image3,
    "image4": image4,
    "image5": image5,
    "description": description,
    "price": price,
    "priceTakhfif": priceTakhfif,
    "isActive": isActive,
    "inventory": inventory,
    "categoryId": categoryId,
    "categoryTitle": categoryTitle,
    "subCategoryId": subCategoryId,
    "subCategoryTitle": subCategoryTitle,
    "isSpecial": isSpecial,
    "isTop": isTop,
    "tartib": tartib,
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


class CoinRequirement {
  final int value;
  final String coinType;
  final int coin;
  final int rCoin;
  final int zCoin;
  final int sCoin;

  CoinRequirement({
    required this.value,
    required this.coinType,
    this.coin = 0,
    this.rCoin = 0,
    this.zCoin = 0,
    this.sCoin = 0,
  });
}
