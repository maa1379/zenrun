import 'package:auto_size_text/auto_size_text.dart';
import 'package:badges/badges.dart' as badge;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/models/shop_product_model.dart';

import '../../../core/widgets/dialog_view.dart';
import '../../../core/widgets/dropDown_widget.dart';
import '../../../generated/assets.dart';
import '../../profile_pages/providers/coin_provider.dart';
import '../../profile_pages/providers/profile_provider.dart';
import '../../profile_pages/providers/shop_product_provider.dart';
import '../providers/basket_provider.dart';
import 'package:toln/toln.dart';

class DetailShopProductPage extends StatefulWidget {
  const DetailShopProductPage({super.key, required this.data});

  final ShopProductModel data;

  @override
  State<DetailShopProductPage> createState() => _DetailShopProductPageState();
}

class _DetailShopProductPageState extends State<DetailShopProductPage> {
  bool checkIsDiscount() {
    return widget.data.coinTakhfif != widget.data.coin;
  }

  @override
  void initState() {
    context.read<ShopProductProvider>().getAllShopProducts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelper.appBar(
        widget.data.title ?? "",
        action: Consumer<BasketProvider>(
          builder: (context, provider, child) {
            return UiHelper.iconBox(
              badge.Badge(
                badgeStyle: const badge.BadgeStyle(
                  badgeColor: ColorsHelper.btn2,
                ),
                badgeContent: Text(
                  provider.badgeCount.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                showBadge: true,
                child: Icon(Icons.shopping_cart_outlined, size: 28),
              ),
              () async {
                await provider.getAndPushFromDb(context, isPush: true);
              },
              color: Colors.transparent,
            );
          },
        ),
      ),
      bottomNavigationBar: _buildNavBtn(),
      body: Container(
        height: 100.h,
        width: 100.w,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.imagesImg4),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          children: [
            Gap(0),
            Image.network(widget.data.image ?? "", height: 25.h, width: 100.w),
            Gap(10),
            Divider(color: ColorsHelper.btn2, indent: 2.5.w, endIndent: 2.5.w),
            Gap(10),
            Container(
              width: 100.w,
              margin: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 10),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: UiHelper.borderRadius16,
                color: ColorsHelper.white,
                boxShadow: UiHelper.shadow1,
              ),
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.description ?? "",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Divider(color: ColorsHelper.btn2),
                  Text(
                    "R Coin Coefficient: x${widget.data.zaribRCoin}".toLn(),
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Text(
                    "S Coin Coefficient: x${widget.data.zaribSCoin}".toLn(),
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Text(
                    "Z Coin Coefficient: x${widget.data.zaribZCoin}".toLn(),
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Text(
                    "You can use this feature ${widget.data.validDay} days after purchase"
                        .toLn(),
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
            Gap(10),
          ],
        ),
      ),
    );
  }

  void _showFinalizePurchaseModal(int price) {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return Consumer<BasketProvider>(
          builder: (context, provider, child) {
            return SafeArea(
              child: AnimatedContainer(
                height: 32.h,
                width: 100.w,
                duration: Duration(milliseconds: 150),
                child: Column(
                  children: [
                    Center(
                      child: AutoSizeText(
                        "Coins: ${ViewHelper.formatAmount(price.toString())}",
                        maxFontSize: 28,
                        minFontSize: 10,
                        style: ThemeHelper.textStyle(
                          fontSize: 16,
                          color: ColorsHelper.black,
                        ),
                      ),
                    ),
                    Divider(color: Colors.grey, endIndent: 50, indent: 50),
                    Gap(10),
                    Center(
                      child: AutoSizeText(
                        "Or pay with other coins:",
                        maxFontSize: 28,
                        minFontSize: 10,
                        style: ThemeHelper.textStyle(
                          fontSize: 16,
                          color: ColorsHelper.black,
                        ),
                      ),
                    ),
                    Gap(10),
                    Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          "Z Coin: ${widget.data.zCoin}",
                          maxFontSize: 28,
                          minFontSize: 10,
                          style: ThemeHelper.textStyle(
                            fontSize: 16,
                            color: ColorsHelper.black,
                          ),
                        ),
                        AutoSizeText(
                          "R Coin: ${widget.data.rCoin}",
                          maxFontSize: 28,
                          minFontSize: 10,
                          style: ThemeHelper.textStyle(
                            fontSize: 16,
                            color: ColorsHelper.black,
                          ),
                        ),
                        AutoSizeText(
                          "S Coin: ${widget.data.sCoin}",
                          maxFontSize: 28,
                          minFontSize: 10,
                          style: ThemeHelper.textStyle(
                            fontSize: 16,
                            color: ColorsHelper.black,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Container(
                      height: 5.h,
                      width: 100.w,
                      margin: EdgeInsets.symmetric(horizontal: 5.w),
                      decoration: BoxDecoration(
                        color: ColorsHelper.btn2,
                        borderRadius: UiHelper.borderRadius50,
                      ),
                      child: Material(
                        borderRadius: UiHelper.borderRadius50,
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            context.pop();
                            provider.coinSelected = null;
                            List<String> coinList = [
                              "Coin",
                              "S Coin",
                              "Z Coin",
                              "R Coin",
                            ];
                            ViewHelper.showLoading();
                            await this
                                .context
                                .read<ProfileProvider>()
                                .getProfile();
                            final profile =
                                this.context.read<ProfileProvider>().profile!;
                            ViewHelper.dismissLoading();
                            _buildShowSelectCoin(() async {
                              ViewHelper.showLoading();
                              String coinType = "";
                              bool isPay = false;
                              switch (provider.coinSelected) {
                                case "S Coin":
                                  coinType = "S";
                                  if (profile.sCoin! >= widget.data.sCoin!) {
                                    isPay = true;
                                  }
                                case "R Coin":
                                  coinType = "R";
                                  if (profile.rCoin! >= widget.data.rCoin!) {
                                    isPay = true;
                                  }
                                case "Z Coin":
                                  coinType = "Z";
                                  if (profile.zCoin! >= widget.data.zCoin!) {
                                    isPay = true;
                                  }
                                case "Coin":
                                  coinType = "C";
                                  if (profile.coin! >= widget.data.coin!) {
                                    isPay = true;
                                  }
                              }
                              if (isPay) {
                                bool status = await this
                                    .context
                                    .read<CoinProvider>()
                                    .setSubCoin(
                                      coinType == "C"
                                          ? widget.data.coin.toString()
                                          : "0",
                                      coinType == "R"
                                          ? widget.data.rCoin.toString()
                                          : "0",
                                      coinType == "Z"
                                          ? widget.data.zCoin.toString()
                                          : "0",
                                      coinType == "S"
                                          ? widget.data.sCoin.toString()
                                          : "0",
                                    );
                                if (status == true) {
                                  await provider.setBasketOneShopProduct(
                                    this.context,
                                    widget.data,
                                  );
                                }
                                ViewHelper.dismissLoading();
                              } else {
                                ViewHelper.showWarningDialog(
                                  context,
                                  "You don't have enough coins",
                                );
                              }
                            }, coinList);
                          },
                          borderRadius: UiHelper.borderRadius50,
                          child: Center(
                            child: AutoSizeText(
                              "Select Coin",
                              maxFontSize: 26,
                              minFontSize: 10,
                              style: ThemeHelper.textStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ColorsHelper.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(25),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _buildShowSelectCoin(Function() onTap, List<String> list) {
    showModalBottomSheet(
      enableDrag: true,
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Consumer<BasketProvider>(
          builder: (context, provider, child) {
            return Container(
              height: 35.h,
              width: 100.w,
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: ListView(
                children: [
                  Gap(15),
                  Center(
                    child: Text(
                      "Select Coin".toLn(),
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Gap(15),
                  Divider(),
                  Gap(15),
                  CustomDropdown<String>(
                    items: list,
                    enabled: true,
                    selectedItem: provider.coinSelected,
                    itemLabel: (value) {
                      return value;
                    },
                    hintText: "Select Coins",
                    onChanged: (value) {
                      provider.coinSelected = value;
                      provider.update();
                    },
                  ),
                  Gap(30),
                  UiHelper.buttonMain2(
                    () {
                      if (provider.coinSelected == null) {
                        ViewHelper.showWarningDialog(
                          context,
                          "Please select the coin",
                        );
                      } else {
                        DialogView.showDanger(
                          context,
                          "Are you sure about the payment?",
                          "",
                          () async {
                            context.pop();
                            onTap();
                          },
                        );
                      }
                    },
                    "Pay",
                    height: 5.h,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavBtn() {
    return Container(
      height: 13.h,
      width: 100.w,
      margin: EdgeInsets.only(bottom: 5.h, left: 2.5.w, right: 2.5.w),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: UiHelper.borderRadius16,
        color: ColorsHelper.white,
        boxShadow: UiHelper.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.data.coin} Coins".toLn(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      decoration: !checkIsDiscount()
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  !checkIsDiscount()
                      ? SizedBox()
                      : Text(
                          "${widget.data.coinTakhfif} Coins".toLn(),
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ],
              ),
              UiHelper.buttonMain2(
                () async {
                  if (context.read<ShopProductProvider>().shopHistoryList.any(
                        (element) => element.isExpire == true,
                      )) {
                    _showFinalizePurchaseModal(widget.data.coinTakhfif ?? 0);
                  } else {
                    ViewHelper.showWarningDialog(
                      context,
                      "You can only have one active and similar product",
                    );
                  }
                },
                "Pay",
                width: 30.w,
                height: 4.h,
                fontSize: 16,
              ),
            ],
          ),
          Text(
            "You can make the purchase if you have other coins.".toLn(),
            style: TextStyle(color: Colors.black, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
