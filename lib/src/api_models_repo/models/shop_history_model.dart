
import 'package:zenrun/src/api_models_repo/models/shop_product_model.dart';

class ShopHistoryModel {
  final int? id;
  final String? email;
  final int? shopProductId;
  final DateTime? date;
  final bool? isPaid;
  final DateTime? expireDate;
  ShopProductModel? data;
  List<ShopProductModel> dataList = [];
  bool get isExpire => expireDate?.isBefore(DateTime.now()) ?? true;

  ShopHistoryModel({
    this.id,
    this.email,
    this.shopProductId,
    this.date,
    this.isPaid,
    this.expireDate,
  });

  factory ShopHistoryModel.fromJson(Map<String, dynamic> json) => ShopHistoryModel(
    id: json["id"],
    email: json["email"],
    shopProductId: json["shopProductId"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    isPaid: json["isPaid"],
    expireDate: json["ExpireDate"] == null ? null : DateTime.parse(json["ExpireDate"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "shopProductId": shopProductId,
    "date": date?.toIso8601String(),
    "isPaid": isPaid,
    "ExpireDate": expireDate?.toIso8601String(),
  };
}