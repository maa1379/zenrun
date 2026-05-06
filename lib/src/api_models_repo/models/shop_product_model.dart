class ShopProductModel {
  final int? id;
  final String? title;
  final String? image;
  final int? coin;
  final int? coinTakhfif;
  final String? description;
  final int? rCoin;
  final int? zCoin;
  final int? sCoin;
  final int? zaribRCoin;
  final int? zaribZCoin;
  final int? zaribSCoin;
  final int? validDay;

  ShopProductModel({
    this.id,
    this.title,
    this.image,
    this.coin,
    this.coinTakhfif,
    this.description,
    this.rCoin,
    this.zCoin,
    this.sCoin,
    this.zaribRCoin,
    this.zaribZCoin,
    this.zaribSCoin,
    this.validDay,
  });

  factory ShopProductModel.fromJson(Map<String, dynamic> json) => ShopProductModel(
    id: json["id"],
    title: json["title"],
    image: json["image"],
    coin: json["coin"],
    coinTakhfif: json["coinTakhfif"],
    description: json["description"],
    rCoin: json["RCoin"],
    zCoin: json["ZCoin"],
    sCoin: json["SCoin"],
    zaribRCoin: json["ZaribRCoin"],
    zaribZCoin: json["ZaribZCoin"],
    zaribSCoin: json["ZaribSCoin"],
    validDay: json["ValidDay"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "image": image,
    "coin": coin,
    "coinTakhfif": coinTakhfif,
    "description": description,
    "RCoin": rCoin,
    "ZCoin": zCoin,
    "SCoin": sCoin,
    "ZaribRCoin": zaribRCoin,
    "ZaribZCoin": zaribZCoin,
    "ZaribSCoin": zaribSCoin,
    "ValidDay": validDay,
  };
}
