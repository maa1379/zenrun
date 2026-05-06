import 'package:flutter/material.dart';
import 'package:zenrun/src/api_models_repo/models/category_model.dart';
import 'package:zenrun/src/api_models_repo/models/product_model.dart';
import 'package:zenrun/src/api_models_repo/models/shop_product_model.dart';

import '../../../core/network/DataState.dart';
import '../../api_models_repo/api_service.dart';

class ShopProvider extends ChangeNotifier {
  bool loading = false;
  void update() => notifyListeners();
  List<ShopProductModel> shopProductList = [];
  List<ProductModel> productList = [];
  List<CategoryModel> categoryList = [];

  // استفاده از متغیر برای جلوگیری از درخواست‌های تکراری در صورت نیاز
  bool _isInitialized = false;

  Future<void> init() async {
    // اگر قبلا لود شده و دیتا داریم، دوباره لود نکن (اختیاری - فعلا غیرفعال برای رفرش)
    // if (_isInitialized) return;

    loading = false; // شروع لودینگ
    // notifyListeners(); // اینجا نیازی نیست چون UI پرش میکند

    await Future.wait([
      getAllShopProducts(),
      getAllProducts(),
      getAllCategory(),
    ]);

    _isInitialized = true;
    loading = true; // پایان لودینگ
    update();
  }

  Future<void> getAllShopProducts() async {
    final res = await ApiService.instance.getAllShopProduct();
    if (res is DataSuccess) {
      shopProductList.clear();
      shopProductList.addAll(res.data ?? []);
    }
  }

  Future<void> getAllProducts() async {
    final res = await ApiService.instance.getAllProducts();
    if (res is DataSuccess) {
      productList.clear();
      productList.addAll(res.data ?? []);
    }
  }

  Future<ProductModel?> getOnProductById(id) async {
    final res = await ApiService.instance.getOnProductById(id);
    if (res is DataSuccess) {
      return res.data?.first;
    }
    return null;
  }

  Future<void> getAllCategory() async {
    final res = await ApiService.instance.getAllCategory();
    if (res is DataSuccess) {
      categoryList.clear();
      categoryList.addAll(res.data ?? []);

      // --- بهینه سازی: دریافت موازی زیرمجموعه ها ---
      await Future.wait(categoryList.map((sub) async {
        final data = await ApiService.instance.getAllSubCategory(
          sub.id.toString(),
        );
        if (data is DataSuccess) {
          sub.subList.addAll(data.data ?? []);
        }
      }));
    }
  }
}