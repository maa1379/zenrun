import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenrun/core/network/DataState.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';

class CoinProvider extends ChangeNotifier {
  bool loading = false;
  String fromCoin = "";
  String? fromCoinSelected;
  String toCoin = "";
  String? toCoinSelected;
  TextEditingController amount = TextEditingController();
  List<String> coinList = ["Coin", "S Coin", "Z Coin", "R Coin"];
  void update() => notifyListeners();

  Future<void> setCoinToCoin(BuildContext context) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.setCoinToCoin(
      amount.text,
      "${fromCoin}T$toCoin",
    );
    if (res is DataSuccess) {
      fromCoin = "";
      toCoin = "";
      fromCoinSelected = null;
      toCoinSelected = null;
      amount.clear();
      await context.read<ProfileProvider>().getProfile();
      context.pop();
      ViewHelper.showSuccessDialog(
        context,
        "The conversion was successfully performed",
      );
    } else {
      ViewHelper.showErrorDialog(context, text: "Failed request");
    }
    ViewHelper.dismissLoading();
  }


  Future<void> setCoinToWallet(BuildContext context) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.setCoinToWallet(amount.text);
    if (res is DataSuccess) {
      amount.clear();
      await context.read<ProfileProvider>().getProfile();
      context.pop();
      ViewHelper.showSuccessDialog(
        context,
        "The conversion was successfully performed",
      );
    } else {
      ViewHelper.showErrorDialog(context, text: "Failed request");
    }
    ViewHelper.dismissLoading();
  }


  Future<bool> setSubCoin(
      String coin,
      String RCoin,
      String ZCoin,
      String SCoin,
      ) async {
    final res = await ApiService.instance.setSubCoin(
      coin: coin,
      RCoin: RCoin,
      ZCoin: ZCoin,
      SCoin: SCoin,
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      return true;
    } else {
      return false;
      // ViewHelper.showErrorDialog(context);
    }
  }

  Future<bool> setAddCoin(
      String coin,
      String RCoin,
      String ZCoin,
      String SCoin,
      ) async {
    final res = await ApiService.instance.setAddCoin(
      coin: coin,
      RCoin: RCoin,
      ZCoin: ZCoin,
      SCoin: SCoin,
    );
    ViewHelper.dismissLoading();
    if (res is DataSuccess) {
      return true;
    } else {
      return false;
      // ViewHelper.showErrorDialog(context);
    }
  }

}
