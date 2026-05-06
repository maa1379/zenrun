import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:zenrun/core/network/DataState.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/src/api_models_repo/api_service.dart';
import 'package:zenrun/src/api_models_repo/models/setting_model.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  SettingModel? settings;
  bool isLoading = false;

  void update() => notifyListeners();

  Future<void> loadSettings() async {
    isLoading = true;
    notifyListeners();
    final res = await ApiService.instance.getSetting();
    if (res is DataSuccess) {
      settings = res.data;
    }
    isLoading = false;
    notifyListeners();
  }

  int priceForMonths(int months) {
    if (settings == null) return 0;
    switch (months) {
      case 1:
        return int.tryParse(settings!.eshterak1Mah ?? '0') ?? 0;
      case 3:
        return int.tryParse(settings!.eshterak3Mah ?? '0') ?? 0;
      case 6:
        return int.tryParse(settings!.eshterak6Mah ?? '0') ?? 0;
      case 12:
        return int.tryParse(settings!.eshterak12Mah ?? '0') ?? 0;
      default:
        return 0;
    }
  }

  Future<void> purchaseWithStripe(
    BuildContext context,
    ProfileProvider profileProvider,
    int months,
  ) async {
    final price = priceForMonths(months);
    ViewHelper.showLoading();
    try {
      ViewHelper.dismissLoading();
      await _presentStripePayment(price);
      ViewHelper.showLoading();
      await _activateSubscription(profileProvider, months);
      ViewHelper.dismissLoading();
      if (context.mounted) {
        ViewHelper.showSuccessDialog(context, "Subscription activated!");
      }
    } on StripeException catch (e) {
      ViewHelper.dismissLoading();
      final msg =
          e.error.localizedMessage ?? e.error.message ?? "Payment cancelled";
      if (context.mounted) ViewHelper.showErrorDialog(context, text: msg);
    } catch (e) {
      ViewHelper.dismissLoading();
      if (context.mounted) {
        ViewHelper.showErrorDialog(
          context,
          text: "Payment failed. Please try again.",
        );
      }
    }
  }

  Future<void> purchaseWithWallet(
    BuildContext context,
    ProfileProvider profileProvider,
    int months,
  ) async {
    final price = priceForMonths(months);
    if (price == 0) {
      ViewHelper.showErrorDialog(
        context,
        text: "Subscription price not available. Please try again.",
      );
      return;
    }
    ViewHelper.showLoading();
    await profileProvider.getProfile();
    final walletBalance = profileProvider.profile?.wallet ?? 0;
    if (walletBalance < price) {
      ViewHelper.dismissLoading();
      if (context.mounted) {
        ViewHelper.showErrorDialog(
          context,
          text: "Insufficient wallet balance.",
        );
      }
      return;
    }
    try {
      await _activateSubscription(
        profileProvider,
        months,
        walletDeduction: price,
      );
      ViewHelper.dismissLoading();
      if (context.mounted) {
        ViewHelper.showSuccessDialog(context, "Subscription activated!");
      }
    } catch (e) {
      ViewHelper.dismissLoading();
      if (context.mounted) {
        ViewHelper.showErrorDialog(
          context,
          text: "Payment failed. Please try again.",
        );
      }
    }
  }

  // WARNING: Secret key must not be in production client code.
  // Move payment-intent creation to a backend server before going live.
  static const _stripeSecretKey =
      'sk_test_51RhHnBBV8sQxphGU24BsLshM4UgvGiAPv20vpkPqgrYtoXzAMQBfNkBhLUVnzU0WZrseV16PPpuQsyv0NuO4KDHz00r0Ma0fne';

  Future<void> _presentStripePayment(int priceInDollars) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        // 'amount': (priceInDollars * 100).toString(),
        'amount': (10 * 100).toString(),
        'currency': 'usd',
        'automatic_payment_methods[enabled]': 'true',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Stripe error: ${response.body}');
    }
    final clientSecret = json.decode(response.body)['client_secret'] as String;

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

  Future<void> _activateSubscription(
    ProfileProvider profileProvider,
    int months, {
    int walletDeduction = 0,
  }) async {
    await profileProvider.getProfile();
    final profile = profileProvider.profile;
    if (profile == null) throw Exception("Profile not found");

    final now = DateTime.now();
    final baseDate =
        (profile.expireEshterak != null && profile.expireEshterak!.isAfter(now))
        ? profile.expireEshterak!
        : now;
    final newExpiry = baseDate.add(Duration(days: months * 30));

    await ApiService.instance.setProfile(
      Bio: profile.bioC.text,
      Coin: profile.coin?.toString(),
      RCoin: profile.rCoin?.toString(),
      SCoin: profile.sCoin?.toString(),
      ZCoin: profile.zCoin?.toString(),
      city: profile.cityC.text,
      country: profile.countryC.text,
      email: profile.emailC.text,
      family: profile.familyC.text,
      followerCount: profile.followerCount?.toString(),
      followingCount: profile.followingCount?.toString(),
      image: profile.imageC.text,
      isActive: profile.isActive?.toString(),
      isMaster: profile.isMaster?.toString(),
      isPrivate: profile.isPrivate?.toString(),
      language: profile.languageC.text,
      lvl: profile.lvl?.toString(),
      mantaghe: profile.stateC.text,
      name: profile.nameC.text,
      phone: profile.phoneC.text,
      postCount: profile.postCount?.toString(),
      type: profile.type,
      username: profile.usernameC.text,
      wallet: walletDeduction > 0
          ? ((profile.wallet ?? 0) - walletDeduction).toString()
          : profile.wallet?.toString(),
      fcm: profile.FCMToken,
      expireEshterak: newExpiry.toIso8601String(),
    );

    await profileProvider.getProfile();
  }
}
