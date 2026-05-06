import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:zenrun/core/network/DataState.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart';
import 'package:zenrun/src/api_models_repo/models/basket_model.dart';
import 'package:zenrun/src/shop_pages/pages/basket_page.dart';

import '../../../core/PrefHelper/PrefHelpers.dart';
import '../../../core/widgets/Costance.dart';
import '../../api_models_repo/models/product_model.dart';
import '../../api_models_repo/models/shop_product_model.dart';

class BasketProvider extends ChangeNotifier {
  List<ProductModel> listOfCartDb = [];
  List<ProductModel> listOfCartCoinProduct = [];
  List<BasketModel> basketList = [];
  int price = 0;
  int realPrice = 0;
  int badgeCount = 0;
  bool loading = false;
  int tabIndex = 0;
  bool isDiscount = false;
  TextEditingController discountedCode = TextEditingController();
  String? coinSelected;
  String disCount = "0";

  Future<void> initCart() async {
    listOfCartDb = await BasketModel.getDB();
    listOfCartDb.removeWhere((element) => element.price == "0");
    _refreshLists();
    notifyListeners();
  }

  Future<void> addProductToDb(ProductModel item, int counts, BuildContext context) async {
    if (listOfCartDb.any((e) => e.id == item.id)) {
      ViewHelper.showErrorDialog(context, text: "This product is in your cart");
      return;
    }
    listOfCartDb.add(item.copy());
    await _saveToDisk();
  }

  Future<void> removeProductFromDb(ProductModel item) async {
    listOfCartDb.removeWhere((element) => element.id == item.id);
    await _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    _refreshLists(); // آپدیت قیمت‌ها و لیست‌های فرعی
    notifyListeners(); // آپدیت UI

    // عملیات سنگین دیتابیس
    await PrefHelpers.removeCartModelDb();
    await BasketModel.saveToDB(listOfCartDb);
  }


  void _refreshLists() {
    listOfCartCoinProduct = listOfCartDb
        .where((element) =>
    element.isCoin == true ||
        element.isRCoin == true ||
        element.isSCoin == true ||
        element.isZCoin == true)
        .toList();

    price = listOfCartDb.fold(
      0,
          (sum, item) => sum + int.parse(item.priceTakhfif ?? "0"),
    );
    realPrice = price;
    badgeCount = listOfCartDb.length;
  }

  void _calculatePrice() {
    price = listOfCartDb.fold(
      0,
          (sum, item) => sum + int.parse(item.priceTakhfif ?? "0"),
    );
    realPrice = price;
  }

  Future<void> setAllPrice() async {
    listOfCartDb = await BasketModel.getDB();
    _calculatePrice();
    notifyListeners();
  }

  void update() => notifyListeners();

  Future<void> getAndPushFromDb(BuildContext context, {bool? isPush}) async {
    // listOfCartDb = await BasketModel.getDB();
    // _refreshLists();

    if (isPush == true) {
      context.to(const BasketPage());
    }
    notifyListeners();
  }

  Future<void> getBasketHistoryList() async {
    final res = await ApiService.instance.getBasketListApi();
    if (res is DataSuccess) {
      basketList.addAll(res.data ?? []);
      for (var item in basketList) {
        final product = await ApiService.instance.basketHistoryListApi(
          item.id.toString(),
        );
        if (product is DataSuccess) {
          item.productList.addAll(product.data ?? []);
        }
      }
      loading = true;
      update();
    } else {}
  }

  Future<void> setBasketOneShopProduct(
      BuildContext context,
      ShopProductModel item,
      ) async {
    // ViewHelper.showLoading();
    final res = await ApiService.instance.setUserShopProduct(
      id: "0",
      isPaid: "true",
      productID: item.id.toString(),
      expireDate: DateTime.now().add(Duration(days: item.validDay ?? 0)).toIso8601String(),
    );
    // ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      ViewHelper.showSuccessDialog(context, "Purchase completed successfully");
      // Navigator.of(context).pop(true);
    } else {
      ViewHelper.showErrorDialog(context);
    }
  }



  Future<String?> setBasketOneProduct(
    BuildContext context,
    ProductModel item,
    String dPrice,
  ) async {
    // ViewHelper.showLoading();
    final res = await ApiService.instance.setBasket(
      basketPrice: dPrice.toString(),
      discountedCode: discountedCode.text.isEmpty
          ? "0"
          : discountedCode.text.toEnglishDigit(),
      discountedPrice: !isDiscount ? dPrice.toString() : dPrice,
      isDiscounted: isDiscount ? "true" : "false",
    );
    // ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      await ApiService.instance.setBasketDetail(
        basketID: res.data.toString(),
        productID: item.id.toString(),
        count: "1",
      );
      return res.data.toString();
      // Navigator.of(context).pop(true);
    } else {
      ViewHelper.showErrorDialog(context);
      return null;
    }
  }

  Future<String?> setBasketProduct(
    BuildContext context,
    ProductModel item,
    String dPrice,
  ) async {
    // ViewHelper.showLoading();
    final res = await ApiService.instance.setBasket(
      basketPrice: dPrice,
      discountedCode: discountedCode.text.isEmpty
          ? "0"
          : discountedCode.text.toEnglishDigit(),
      discountedPrice: !isDiscount ? dPrice : dPrice,
      isDiscounted: isDiscount ? "true" : "false",
    );
    if (res is DataSuccess) {
        for (var i
            in listOfCartDb
                .where(
                  (element) =>
                      element.isCoin == true ||
                      element.isRCoin == true ||
                      element.isSCoin == true ||
                      element.isZCoin == true,
                )
                .toList()) {
          await ApiService.instance.setBasketDetail(
            basketID: res.data.toString(),
            productID: i.id.toString(),
            count: "1",
          );
        }
      return res.data.toString();
    } else {
      ViewHelper.showErrorDialog(context);
    return null;
    }
  }

  Future<void> verifyOfferCode(BuildContext context) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.verifyDiscount(
      discountedCode.text.toEnglishDigit(),
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      disCount = res.data.toString();
      update();
    }
    if (res is DataFailed) {
      ViewHelper.showErrorDialog(context, text: res.error.toString());
    }
  }

  // WARNING: Secret key must not be in production client code.
  // Move payment-intent creation to a backend server before going live.
  static const _stripeSecretKey =
      'sk_test_51RhHnBBV8sQxphGU24BsLshM4UgvGiAPv20vpkPqgrYtoXzAMQBfNkBhLUVnzU0WZrseV16PPpuQsyv0NuO4KDHz00r0Ma0fne';

  Future<String> fetchClientSecretDirectly(int amountInCents) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amountInCents.toString(),
        'currency': 'usd',
        'automatic_payment_methods[enabled]': 'true',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['client_secret'] as String;
    } else {
      throw Exception('Stripe error: ${response.body}');
    }
  }

  Future<void> initPaymentSheetWithAppleOrGooglePay(int priceInDollars) async {
    final clientSecret = await fetchClientSecretDirectly(priceInDollars * 100);

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'ZenRun',
        applePay: PaymentSheetApplePay(merchantCountryCode: 'US'),
        googlePay: PaymentSheetGooglePay(
          merchantCountryCode: 'US',
          testEnv: true,
        ),
        style: ThemeMode.light,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  Future<bool> setBasketTruePay(String basketId, bool isCoinProduct, {String? pId}) async {
    final res = await ApiService.instance.setBasketTruePay(basketID: basketId);
    if (res is DataSuccess) {
      if (isCoinProduct && pId != null) {
        final itemToRemove = listOfCartDb.firstWhere(
                (element) => element.id.toString() == pId,
            orElse: () => ProductModel() // جلوگیری از کرش اگر پیدا نشد
        );
        if(itemToRemove.id != null) {
          await removeProductFromDb(itemToRemove);
        }
      } else {
        // پرداخت کامل سبد خرید معمولی
        await PrefHelpers.removeCartModelDb();
        listOfCartDb.clear();
        discountedCode.clear();
        isDiscount = false;
        await _saveToDisk();
      }
      return true;
    }
    return false;
  }
}
