import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/custom_sacffold.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';
import 'package:zenrun/src/profile_pages/providers/wallet_provider.dart';

import '../../../core/widgets/Costance.dart';
import '../../../core/widgets/dialog_view.dart';
import '../../../generated/assets.dart';
import '../../api_models_repo/api_service.dart';
import '../../shop_pages/providers/basket_provider.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, this.withScaffold});

  final bool? withScaffold;
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  TextEditingController amount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "Wallet",
      withScaffold: widget.withScaffold == true,
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          return SizedBox(
            height: 100.h,
            width: 100.w,
            child: Column(
              children: [
                Gap(4.h),
                Center(
                  child: Container(
                    height: 20.h,
                    width: 90.w,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      image: DecorationImage(
                        image: AssetImage(Assets.imagesImg9),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.h, right: 12.w),
                            child: Image.asset(
                              Assets.imagesMoneyStack,
                              opacity: AlwaysStoppedAnimation(0.3),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 6.w, top: 4.h),
                            child: Text(
                              "Total Balance".toLn(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 6.w, top: 8.h),
                            child: Consumer<ProfileProvider>(
                              builder: (context, provider, child) {
                                return Text(
                                  "\$${provider.profile?.wallet.toString().seRagham() ?? 0}"
                                      .toLn(),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Gap(4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        provider.amount.text = "50";
                        provider.update();
                      },
                      child: Chip(
                        label: Text("\$50".toLn()),
                        side: BorderSide(color: ColorsHelper.btn1),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        provider.amount.text = "100";
                        provider.update();
                      },
                      child: Chip(
                        label: Text("\$100".toLn()),
                        side: BorderSide(color: ColorsHelper.btn1),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        provider.amount.text = "200";
                        provider.update();
                      },
                      child: Chip(
                        label: Text("\$200".toLn()),
                        side: BorderSide(color: ColorsHelper.btn1),
                      ),
                    ),
                  ],
                ),
                Gap(1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        provider.amount.text = "500";
                        provider.update();
                      },
                      child: Chip(
                        label: Text("\$500".toLn()),
                        side: BorderSide(color: ColorsHelper.btn1),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        provider.amount.text = "1000";
                        provider.update();
                      },
                      child: Chip(
                        label: Text("\$1,000".toLn()),
                        side: BorderSide(color: ColorsHelper.btn1),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        provider.amount.text = "2000";
                        provider.update();
                      },
                      child: Chip(
                        label: Text("\$2,000".toLn()),
                        side: BorderSide(color: ColorsHelper.btn1),
                      ),
                    ),
                  ],
                ),
                Gap(4.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: UiHelper.textFormField(
                    provider.amount,
                    false,
                    () {},
                    "Amount",
                    (p0) {},
                    textAlign: TextAlign.start,
                  ),
                ),
                Spacer(),
                UiHelper.buttonMain2(
                  () {
                    if (provider.amount.text.isEmpty) {
                      ViewHelper.showWarningDialog(
                        context,
                        "Please write amount",
                      );
                    } else {
                      DialogView.showDanger(
                        context,
                        "Are you sure you want to do this?",
                        "",
                        () async {
                          await provider.setWalletToCoin(context);
                        },
                      );
                    }
                  },
                  "Send To Coin",
                  width: 85.w,
                ),
                Gap(15),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: UiHelper.buttonMain2(
                    () async {
                      final amountText = provider.amount.text.trim();
                      if (amountText.isEmpty) {
                        ViewHelper.showWarningDialog(
                            context, "Please enter an amount");
                        return;
                      }
                      final amountInt = int.tryParse(amountText);
                      if (amountInt == null || amountInt <= 0) {
                        ViewHelper.showWarningDialog(
                            context, "Please enter a valid amount");
                        return;
                      }
                      try {
                        await context
                            .read<BasketProvider>()
                            .initPaymentSheetWithAppleOrGooglePay(amountInt);
                        // On success — top up wallet via backend
                        await ApiService.instance.setWallet(
                          ((context.read<ProfileProvider>().profile?.wallet ??
                                      0) +
                                  amountInt)
                              .toString(),
                        );
                        await context.read<ProfileProvider>().getProfile();
                        ViewHelper.showSuccessDialog(
                            context, "Wallet topped up successfully!");
                        provider.amount.clear();
                        provider.update();
                      } catch (_) {}
                    },
                    "Top Up Wallet",
                    width: 85.w,
                    height: 4.5.h,
                  ),
                ),
                Gap(5.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
