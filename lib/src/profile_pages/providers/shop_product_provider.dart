import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:zenrun/core/network/DataState.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart';
import 'package:zenrun/src/api_models_repo/models/shop_history_model.dart';

import '../../api_models_repo/models/shop_product_model.dart';

class ShopProductProvider extends ChangeNotifier {
  bool loading = false;
  List<ShopHistoryModel> shopHistoryList = [];
  List<ShopProductModel> shopProductList = [];
  void update() => notifyListeners();

  Future<void> getShopProductHistory() async {
    final res = await ApiService.instance.getUserShopHistoryList();
    if (res is DataSuccess) {
      shopHistoryList.clear();
      shopProductList.clear();
      shopHistoryList.addAll(res.data ?? []);
      await getAllShopProducts();
      for (var item in shopHistoryList) {
        item.dataList.addAll(shopProductList);
        item.data = shopProductList.firstWhereOrNull(
          (element) =>
              element.id == item.shopProductId && !item.isExpire,
        );
      }
      loading = true;
      update();
    } else {}
  }

  Future<void> getAllShopProducts() async {
    final res = await ApiService.instance.getAllShopProduct();
    if (res is DataSuccess) {
      shopProductList.clear();
      shopProductList.addAll(res.data ?? []);
    } else {}
  }

}
