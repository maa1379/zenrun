import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/src/profile_pages/providers/coin_provider.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';

import '../../../core/widgets/Costance.dart';
import '../../../core/widgets/custom_sacffold.dart';
import '../../../core/widgets/dialog_view.dart';
import '../../../core/widgets/dropDown_widget.dart';
import '../../../generated/assets.dart';
import '../widgets/coin_card_widget.dart';
import 'package:toln/toln.dart';

class MyCoinPage extends StatefulWidget {
  const MyCoinPage({super.key});

  @override
  State<MyCoinPage> createState() => _MyCoinPageState();
}

class _MyCoinPageState extends State<MyCoinPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(title: "My Coins", body: _buildCoinChart());
  }

  Widget _buildCoinChart() {
    return ListView(
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
                      Assets.imagesCoin1,
                      opacity: AlwaysStoppedAnimation(0.3),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 6.w, top: 4.h),
                    child: Text(
                      "Total Main Coin".toLn(),
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
                          provider.profile?.coin.toString().seRagham() ?? "0",
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
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 5.w),
            child: Text(
              "Earning Coins".toLn(),
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Gap(2.h),
        _buildCoinCard(),
        Gap(10.h),
        Center(
          child: UiHelper.buttonMain2(
            () {
              context.read<CoinProvider>().toCoinSelected = null;
              context.read<CoinProvider>().fromCoinSelected = null;
              context.read<CoinProvider>().fromCoin = "";
              context.read<CoinProvider>().toCoin = "";
              context.read<CoinProvider>().amount.clear();
              _buildShowConvertCTC();
            },
            "Convert coin to coin",
            width: 90.w,
            height: 5.5.h,
          ),
        ),
        Gap(2.h),
        Center(
          child: UiHelper.buttonMain2(
            () {
              context.read<CoinProvider>().amount.clear();
              _buildShowConvertCTW();
            },
            "Send coin to wallet",
            width: 90.w,
            height: 5.5.h,
          ),
        ),
      ],
    );
  }

  Center _buildCoinCard() {
    return Center(
      child: SizedBox(
        height: 16.h,
        width: 90.w,
        child: Consumer<ProfileProvider>(
          builder: (context, provider, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10,
              children: [
                CoinCard(
                  onTap: () {},
                  avatarText: "S",
                  value: provider.profile?.sCoin.toString().seRagham() ?? "0",
                  title: "Coins",
                  backgroundColor: const Color(0xffE0533D),
                ),
                CoinCard(
                  onTap: () {},
                  avatarText: "R",
                  value: provider.profile?.rCoin.toString().seRagham() ?? "0",
                  title: "Coins",
                  backgroundColor: const Color(0xffE78C9D),
                ),
                CoinCard(
                  onTap: () {},
                  avatarText: "Z",
                  value: provider.profile?.zCoin.toString().seRagham() ?? "0",
                  title: "Coins",
                  backgroundColor: const Color(0xff377CC8),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _buildShowConvertCTC() {
    showModalBottomSheet(
      enableDrag: true,
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Consumer<CoinProvider>(
          builder: (context, provider, child) {
            final List<String> fromItems = provider.coinList
                .where((e) => e != provider.toCoinSelected)
                .toList();
            final List<String> toItems = provider.coinList
                .where((e) => e != provider.fromCoinSelected)
                .toList();
            return Container(
              height: 60.h,
              width: 100.w,
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: ListView(
                children: [
                  Gap(15),
                  Center(
                    child: Text(
                      "Convert Coin".toLn(),
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Gap(15),
                  Divider(),
                  Gap(15),
                  CustomDropdown<String>(
                    items: fromItems,
                    enabled: true,
                    selectedItem: provider.fromCoinSelected,
                    itemLabel: (value) {
                      return value;
                    },
                    hintText: "From Coin",
                    onChanged: (value) {
                      provider.fromCoinSelected = value;
                      switch (value) {
                        case "S Coin":
                          provider.fromCoin = "S";
                        case "R Coin":
                          provider.fromCoin = "R";
                        case "Z Coin":
                          provider.fromCoin = "Z";
                        case "Coin":
                          provider.fromCoin = "C";
                      }
                      provider.update();
                    },
                  ),
                  Gap(15),
                  CustomDropdown<String>(
                    items: toItems,
                    selectedItem: provider.toCoinSelected,
                    itemLabel: (value) {
                      return value;
                    },
                    hintText: "To Coin",
                    enabled: true,
                    onChanged: (value) {
                      provider.toCoinSelected = value;
                      switch (value) {
                        case "S Coin":
                          provider.toCoin = "S";
                        case "R Coin":
                          provider.toCoin = "R";
                        case "Z Coin":
                          provider.toCoin = "Z";
                        case "Coin":
                          provider.toCoin = "C";
                      }
                      provider.update();
                    },
                  ),
                  Gap(15),
                  UiHelper.textFormField(
                    provider.amount,
                    false,
                    () {},
                    "Amount",
                    (value) {},
                    borderColor: ColorsHelper.btn2,
                    textInputType: TextInputType.number,
                    textAlign: TextAlign.left,
                    maxLine: 1,
                  ),
                  Gap(30),
                  UiHelper.buttonMain2(() {
                    if (provider.toCoinSelected == null ||
                        provider.toCoinSelected == null ||
                        provider.amount.text.isEmpty) {
                      ViewHelper.showWarningDialog(
                        context,
                        "Please complete the form.",
                      );
                    } else {
                      DialogView.showDanger(
                        context,
                        "Are you sure you want to do this?",
                        "",
                        () async {
                          await provider.setCoinToCoin(context);
                        },
                      );
                    }
                  }, "Convert"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _buildShowConvertCTW() {
    showModalBottomSheet(
      enableDrag: true,
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Consumer<CoinProvider>(
          builder: (context, provider, child) {
            return Container(
              height: 40.h,
              width: 100.w,
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: ListView(
                children: [
                  Gap(15),
                  Center(
                    child: Text(
                      "Send coin to wallet".toLn(),
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Gap(15),
                  Divider(),
                  Gap(15),
                  UiHelper.textFormField(
                    provider.amount,
                    false,
                    () {},
                    "Amount",
                    (value) {},
                    borderColor: ColorsHelper.btn2,
                    textInputType: TextInputType.number,
                    textAlign: TextAlign.left,
                    maxLine: 1,
                  ),
                  Gap(30),
                  UiHelper.buttonMain2(() {
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
                          await provider.setCoinToWallet(context);
                        },
                      );
                    }
                  }, "Send to wallet"),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
