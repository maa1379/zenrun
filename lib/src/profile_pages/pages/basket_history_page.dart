import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/custom_sacffold.dart';
import 'package:zenrun/core/widgets/extetions.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/shop_pages/providers/basket_provider.dart';
import 'package:zenrun/src/shop_pages/providers/shop_provider.dart';

import '../../shop_pages/pages/detail_product_page.dart';
import 'package:toln/toln.dart';

class BasketHistoryPage extends StatefulWidget {
  const BasketHistoryPage({super.key});

  @override
  State<BasketHistoryPage> createState() => _BasketHistoryPageState();
}

class _BasketHistoryPageState extends State<BasketHistoryPage> {
  @override
  void initState() {
    context.read<BasketProvider>().getBasketHistoryList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        context.read<BasketProvider>().loading = false;
        context.read<BasketProvider>().basketList.clear();
      },
      child: CustomScaffold(
        title: "Cart History",
        body: Consumer<BasketProvider>(
          builder: (context, provider, child) {
            if (!provider.loading) {
              return UiHelper.showLoading();
            }
            return RefreshIndicator(
              onRefresh: () async {
                provider.loading = false;
                provider.update();
                await provider.getBasketHistoryList();
              },
              child: ListView.builder(
                itemCount: provider.basketList.reversed.length,
                itemBuilder: (context, index) {
                  final item = provider.basketList.reversed.toList()[index];
                  return Container(
                    width: 100.w,
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(
                      horizontal: 2.5.w,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ColorsHelper.white,
                      borderRadius: UiHelper.borderRadius16,
                      border: Border.all(color: ColorsHelper.btn2, width: 1.5),
                    ),
                    child: Column(
                      spacing: 10,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Status:".toLn(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              item.isPaid == true ? "Paid" : "Unpaid",
                              style: TextStyle(
                                color: item.isPaid == true
                                    ? Colors.green
                                    : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total price:".toLn(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${item.totalPriceTakhfif.toString().seRagham()} coin / \$"
                                  .toLn(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Date:".toLn(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              item.date?.formatToText() ?? "",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Divider(endIndent: 50, indent: 50),
                        Text(
                          "Products list".toLn(),
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: item.productList.length,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final product = item.productList[index];
                            return Container(
                              width: 100.w,
                              padding: EdgeInsets.all(12),
                              margin: EdgeInsets.symmetric(
                                horizontal: 2.5.w,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: ColorsHelper.white,
                                borderRadius: UiHelper.borderRadius16,
                                boxShadow: UiHelper.shadow2,
                                border: Border.all(
                                  color: ColorsHelper.btn1,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                spacing: 10,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Product title:".toLn(),
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        product.productTitle ?? "",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Product price:".toLn(),
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        spacing: 10,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "\$${product.price}".toLn(),
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              decoration: !product
                                                      .checkIsDiscount()
                                                  ? null
                                                  : TextDecoration.lineThrough,
                                            ),
                                          ),
                                          !product.checkIsDiscount()
                                              ? SizedBox()
                                              : Text(
                                                  "\$${product.priceTakhfif}"
                                                      .toLn(),
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  UiHelper.buttonMain2(
                                    () async {
                                      ViewHelper.showLoading();
                                      final productData = await context
                                          .read<ShopProvider>()
                                          .getOnProductById(
                                            product.productId.toString(),
                                          );
                                      ViewHelper.dismissLoading();
                                      if (productData != null) {
                                        context.to(
                                          DetailProductPage(
                                            data: productData,
                                            isPaid: true,
                                          ),
                                        );
                                      }
                                    },
                                    "Detail page",
                                    width: 25.w,
                                    height: 4.h,
                                    fontSize: 14,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
