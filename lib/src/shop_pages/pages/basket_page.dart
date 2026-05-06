import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gap/gap.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/dialog_view.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';
import 'package:zenrun/src/shop_pages/providers/basket_provider.dart';

import '../../../core/widgets/dropDown_widget.dart';
import '../../../generated/assets.dart';
import '../../profile_pages/pages/basket_history_page.dart';
import '../../profile_pages/providers/coin_provider.dart';

class BasketPage extends StatefulWidget {
  const BasketPage({super.key});

  @override
  State<BasketPage> createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);

    tabController.addListener(() {
      if (tabController.indexIsChanging || tabController.animation != null) {
        context.read<BasketProvider>().tabIndex = tabController.index;
        setState(() {});
      }
    });

    // بارگذاری اولیه دیتا
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BasketProvider>().initCart();
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BasketProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBody: true,
          bottomNavigationBar: provider.tabIndex == 0
              ? _buildNavBtn()
              : SizedBox(
                  height: 8.h,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Note: You can pay with your coins".toLn(),
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    ],
                  ),
                ),
          appBar: UiHelper.appBar("My Cart"),
          body: Container(
            height: 100.h,
            width: 100.w,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesImg4),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 6.h,
                  width: 100.w,
                  child: TabBar(
                    controller: tabController,
                    onTap: (value) {
                      provider.tabIndex = value;
                      provider.update();
                    },
                    tabs: [
                      Tab(text: "Payment with gateway"),
                      Tab(text: "Pay with Coins"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    controller: tabController,
                    children: [
                      _buildTabOne(provider, context),
                      _buildTabTwo(provider, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabOne(BasketProvider provider, BuildContext context) {
    provider.listOfCartDb.removeWhere((element) => element.price == "0");
    return (provider.listOfCartDb.isEmpty)
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Center(
                child: Text(
                  "Cart is empty".toLn(),
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              UiHelper.buttonMain2(
                () {
                  context.to(BasketHistoryPage());
                },
                "go to History",
                width: 50.w,
                height: 4.h,
                fontSize: 14,
              ),
            ],
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: provider.listOfCartDb.length,
            itemBuilder: (context, index) {
              final item = provider.listOfCartDb[index];
              return Container(
                // height: 15.h,
                width: 100.w,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 2.5.w),
                decoration: BoxDecoration(
                  color: ColorsHelper.white,
                  borderRadius: UiHelper.borderRadius16,
                  boxShadow: UiHelper.shadow2,
                  border: Border.all(color: ColorsHelper.btn1, width: 1.5),
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    FittedBox(
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.network(
                          item.image1 ?? "",
                          fit: BoxFit.cover,
                          height: 15.h,
                          width: 50.w,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        spacing: 10,
                        children: [
                          Text(
                            item.title ?? "",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          // Row(
                          //   spacing: 15,
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: [
                          //     Text(
                          //       "\$${item.price}".toLn(),
                          //       style: TextStyle(
                          //         color: Colors.black,
                          //         fontSize: 16,
                          //         decoration: !item.checkIsDiscount()
                          //             ? null
                          //             : TextDecoration.lineThrough,
                          //       ),
                          //     ),
                          //     !item.checkIsDiscount()
                          //         ? SizedBox()
                          //         : Text(
                          //             "\$${item.priceTakhfif}".toLn(),
                          //             style: TextStyle(
                          //               color: Colors.red,
                          //               fontSize: 16,
                          //               fontWeight: FontWeight.w600,
                          //             ),
                          //           ),
                          //   ],
                          // ),
                          UiHelper.buttonMain2(
                            () async {
                              await context
                                  .read<BasketProvider>()
                                  .removeProductFromDb(item);
                            },
                            "Delete",
                            width: 20.w,
                            height: 4.h,
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildTabTwo(BasketProvider provider, BuildContext context) {
    return (provider.listOfCartCoinProduct.isEmpty)
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Center(
                child: Text(
                  "Cart is empty".toLn(),
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              UiHelper.buttonMain2(
                () {
                  context.to(BasketHistoryPage());
                },
                "go to History",
                width: 50.w,
                height: 4.h,
                fontSize: 14,
              ),
            ],
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: provider.listOfCartCoinProduct.length,
            itemBuilder: (context, index) {
              final item = provider.listOfCartCoinProduct[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 2.5.w),
                child: Column(
                  children: [
                    Container(
                      // height: 16.h,
                      width: 100.w,
                      decoration: BoxDecoration(
                        color: ColorsHelper.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          topLeft: Radius.circular(16),
                        ),
                        boxShadow: UiHelper.shadow2,
                        border: Border.all(
                          color: ColorsHelper.btn1,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        spacing: 10,
                        children: [
                          FittedBox(
                            child: ClipRRect(
                              borderRadius: BorderRadiusGeometry.only(
                                topLeft: Radius.circular(16),
                                // bottomLeft: Radius.circular(16),
                              ),
                              child: Image.network(
                                item.image1 ?? "",
                                fit: BoxFit.cover,
                                height: 16.h,
                                width: 50.w,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 10,
                              children: [
                                Center(
                                  child: Text(
                                    item.title ?? "",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: item.isCoin ?? false,
                                  child: Text(
                                    "Coin: ${item.coinValue} coins".toLn(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: item.isSCoin ?? false,
                                  child: Text(
                                    "S Coin: ${item.sCoinValue} coins".toLn(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: item.isZCoin ?? false,
                                  child: Text(
                                    "Z Coin: ${item.zCoinValue} coins".toLn(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: item.isRCoin ?? false,
                                  child: Text(
                                    "R Coin: ${item.rCoinValue} coins".toLn(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 4.h,
                      width: 100.w,
                      // margin: EdgeInsets.only(bottom: 5.h),
                      decoration: BoxDecoration(
                        color: ColorsHelper.btn2,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Material(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            provider.coinSelected = null;
                            List<String> coinList = [];
                            if (item.isCoin == true) {
                              coinList.add("Coin");
                            }
                            if (item.isSCoin == true) {
                              coinList.add("S Coin");
                            }
                            if (item.isRCoin == true) {
                              coinList.add("R Coin");
                            }
                            if (item.isZCoin == true) {
                              coinList.add("Z Coin");
                            }
                            ViewHelper.showLoading();
                            await context.read<ProfileProvider>().getProfile();
                            final profile = context
                                .read<ProfileProvider>()
                                .profile!;
                            ViewHelper.dismissLoading();
                            _buildShowSelectCoin(() async {
                              ViewHelper.showLoading();
                              String coinType = "";
                              bool isPay = false;
                              switch (provider.coinSelected) {
                                case "S Coin":
                                  coinType = "S";
                                  if (profile.sCoin! >= item.sCoinValue!) {
                                    isPay = true;
                                  }
                                case "R Coin":
                                  coinType = "R";
                                  if (profile.rCoin! >= item.rCoinValue!) {
                                    isPay = true;
                                  }
                                case "Z Coin":
                                  coinType = "Z";
                                  if (profile.zCoin! >= item.zCoinValue!) {
                                    isPay = true;
                                  }
                                case "Coin":
                                  coinType = "C";
                                  if (profile.coin! >= item.coinValue!) {
                                    isPay = true;
                                  }
                              }
                              if (isPay) {
                                String? basketId = await provider
                                    .setBasketOneProduct(
                                      context,
                                      item,
                                      coinType == "C"
                                          ? item.coinValue.toString()
                                          : coinType == "R"
                                          ? item.rCoinValue.toString()
                                          : coinType == "Z"
                                          ? item.zCoinValue.toString()
                                          : coinType == "S"
                                          ? item.sCoinValue.toString()
                                          : "0",
                                    );
                                bool status = await context
                                    .read<CoinProvider>()
                                    .setSubCoin(
                                      coinType == "C"
                                          ? item.coinValue.toString()
                                          : "0",
                                      coinType == "R"
                                          ? item.rCoinValue.toString()
                                          : "0",
                                      coinType == "Z"
                                          ? item.zCoinValue.toString()
                                          : "0",
                                      coinType == "S"
                                          ? item.sCoinValue.toString()
                                          : "0",
                                    );
                                if (status == true) {
                                  provider.setBasketTruePay(
                                    basketId!,
                                    true,
                                    pId: item.id.toString(),
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
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Center(
                            child: AutoSizeText(
                              "Pay with coins",
                              maxFontSize: 30,
                              minFontSize: 12,
                              style: ThemeHelper.textStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: ColorsHelper.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildNavBtn() {
    return Consumer<BasketProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 14.h,
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
                        "\$${provider.price}".toLn(),
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
                      if (provider.listOfCartDb.isNotEmpty) {
                        _showFinalizePurchaseModal(provider.price);
                      }
                    },
                    "Finalize Purchase",
                    width: 45.w,
                    height: 4.h,
                    fontSize: 12,
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
      },
    );
  }

  void _showFinalizePurchaseModal(int price) {
    context.read<BasketProvider>().isDiscount = false;
    context.read<BasketProvider>().discountedCode.clear();
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return Consumer<BasketProvider>(
          builder: (context, provider, child) {
            return AnimatedContainer(
              height: provider.isDiscount ? 50.h : 30.h,
              width: 100.w,
              duration: Duration(milliseconds: 150),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AutoSizeText(
                        "I have a discount code",
                        maxFontSize: 24,
                        minFontSize: 12,
                        style: ThemeHelper.textStyle(
                          fontSize: 16,
                          color: ColorsHelper.black,
                        ),
                      ),
                      Checkbox(
                        value: provider.isDiscount,
                        onChanged: (value) {
                          provider.isDiscount = value!;
                          provider.update();
                        },
                        activeColor: ColorsHelper.btn2,
                        checkColor: Colors.white,
                      ),
                    ],
                  ),
                  Builder(
                    builder: (c) {
                      if (!provider.isDiscount) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          const Gap(30),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: UiHelper.textFormField(
                              provider.discountedCode,
                              false,
                              () {},
                              "xxxxxxx",
                              (value) {
                                provider.discountedCode.text = value;
                              },
                              borderColor: ColorsHelper.black,
                              textInputType: TextInputType.number,
                            ),
                          ),
                          const Gap(15),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: UiHelper.buttonMain2(
                              () async {
                                await provider.verifyOfferCode(context);
                                if (provider.disCount.endsWith("%")) {
                                  price = int.parse(
                                    ViewHelper.calculateDiscountEn(
                                      price,
                                      int.parse(
                                        provider.disCount.replaceAll("%", ""),
                                      ),
                                    ),
                                  );
                                } else {}
                                price = price - int.parse(provider.disCount);
                                provider.update();
                              },
                              "Check",
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ).animate().fade();
                    },
                  ),
                  const Spacer(),
                  Center(
                    child: AutoSizeText(
                      "Total: \$${ViewHelper.formatAmount(price.toString())}",
                      maxFontSize: 28,
                      minFontSize: 10,
                      style: ThemeHelper.textStyle(
                        fontSize: 16,
                        color: ColorsHelper.black,
                      ),
                    ),
                  ),
                  Divider(color: Colors.grey, endIndent: 50, indent: 50),
                  const Gap(25),
                  Consumer<ProfileProvider>(
                    builder: (context, profile, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          Container(
                            height: 5.5.h,
                            width: 44.w,
                            decoration: BoxDecoration(
                              color: ColorsHelper.btn2,
                              borderRadius: UiHelper.borderRadius50,
                            ),
                            child: Material(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(50),
                                topRight: Radius.circular(50),
                              ),
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  DialogView.showDanger(
                                    this.context,
                                    "Are you sure about the payment?",
                                    "",
                                    () async {
                                      context.pop();
                                      ViewHelper.showLoading();
                                      await profile.getProfile();
                                      if (profile.profile!.wallet! >= price) {
                                        final basketId = await provider
                                            .setBasketProduct(
                                              this.context,
                                              this.context
                                                  .read<BasketProvider>()
                                                  .listOfCartCoinProduct
                                                  .first,
                                              price.toString().toEnglishDigit(),
                                            );
                                        if (basketId != null) {
                                          final status = await profile
                                              .payByWallet(this.context, price);
                                          if (status == true) {
                                            await provider.setBasketTruePay(
                                              basketId,
                                              false,
                                            );
                                          }
                                        }
                                        ViewHelper.dismissLoading();
                                      } else {
                                        ViewHelper.dismissLoading();
                                        ViewHelper.showErrorDialog(
                                          this.context,
                                          text:
                                              "The amount is more than your wallet balance.",
                                        );
                                      }
                                    },
                                  );
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(50),
                                  topRight: Radius.circular(50),
                                ),
                                child: Center(
                                  child: AutoSizeText(
                                    "Pay with wallet",
                                    maxFontSize: 30,
                                    minFontSize: 12,
                                    style: ThemeHelper.textStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: ColorsHelper.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 5.5.h,
                            width: 44.w,
                            decoration: BoxDecoration(
                              color: ColorsHelper.btn2,
                              borderRadius: UiHelper.borderRadius50,
                            ),
                            child: Material(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(50),
                                topRight: Radius.circular(50),
                              ),
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  ViewHelper.showLoading();
                                  try {
                                    final String? basketId =
                                        await provider.setBasketProduct(
                                      this.context,
                                      provider.listOfCartDb.first,
                                      price.toString().toEnglishDigit(),
                                    );
                                    if (basketId == null) {
                                      ViewHelper.dismissLoading();
                                      return;
                                    }
                                    ViewHelper.dismissLoading();
                                    await provider
                                        .initPaymentSheetWithAppleOrGooglePay(
                                            price);
                                    ViewHelper.showLoading();
                                    await provider.setBasketTruePay(
                                        basketId, false);
                                    ViewHelper.dismissLoading();
                                    ViewHelper.showSuccessDialog(
                                      this.context,
                                      "Payment successful!",
                                    );
                                  }
                                  on StripeException catch (e) {
                                    ViewHelper.dismissLoading();
                                    final msg = e.error.localizedMessage ??
                                        e.error.message ??
                                        "Payment cancelled";
                                    ViewHelper.showErrorDialog(this.context,
                                        text: msg);
                                  }
                                  catch (e) {
                                    ViewHelper.dismissLoading();
                                    ViewHelper.showErrorDialog(this.context,
                                        text: "Payment failed. Try again.");
                                  }
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(50),
                                  topRight: Radius.circular(50),
                                ),
                                child: Center(
                                  child: AutoSizeText(
                                    "Google / Apple Pay",
                                    maxFontSize: 30,
                                    minFontSize: 10,
                                    style: ThemeHelper.textStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: ColorsHelper.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Gap(6.h),
                ],
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
}
