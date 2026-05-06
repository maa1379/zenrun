import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';

import '../../../core/network/DataState.dart';
import '../../../core/widgets/Costance.dart';
import '../../api_models_repo/api_service.dart';

class WalletProvider extends ChangeNotifier {
  bool loading = false;
  TextEditingController amount = TextEditingController();
  void update() => notifyListeners();

  Future<void> setWalletToCoin(BuildContext context) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.setWalletToCoin(amount.text);
    if (res is DataSuccess) {
      amount.clear();
      await context.read<ProfileProvider>().getProfile();
      ViewHelper.showSuccessDialog(
        context,
        "The conversion was successfully performed",
      );
    } else {
      ViewHelper.showErrorDialog(context, text: "Failed request");
    }
    ViewHelper.dismissLoading();
  }
}
