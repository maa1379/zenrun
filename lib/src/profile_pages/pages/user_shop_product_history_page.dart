import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/custom_sacffold.dart';
import 'package:zenrun/core/widgets/extetions.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/shop_pages/pages/detail_shop_product_page.dart';

import '../providers/shop_product_provider.dart';
import 'package:toln/toln.dart';

class UserShopProductHistoryPage extends StatefulWidget {
  const UserShopProductHistoryPage({super.key});

  @override
  State<UserShopProductHistoryPage> createState() =>
      _UserShopProductHistoryPageState();
}

class _UserShopProductHistoryPageState
    extends State<UserShopProductHistoryPage> {
  @override
  void initState() {
    context.read<ShopProductProvider>().getShopProductHistory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        context.read<ShopProductProvider>().loading = false;
        context.read<ShopProductProvider>().update();
      },
      child: CustomScaffold(
        title: "Zen Product History",
        body: Consumer<ShopProductProvider>(
          builder: (context, provider, child) {
            if (!provider.loading) {
              return UiHelper.showLoading();
            }
            if (provider.shopHistoryList.isEmpty) {
              return Center(child: Text("Empty".toLn()));
            }
            return ListView.builder(
              itemCount: provider.shopHistoryList.length,
              itemBuilder: (context, index) {
                final item = provider.shopHistoryList[index];
                return Container(
                  width: 100.w,
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 10),
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
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          Text(
                            item.isExpire == false ? "No Expire" : "Expired",
                            style: TextStyle(
                              color: item.isExpire == false
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
                            "Expire date".toLn(),
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          Text(
                            item.expireDate?.formatToText() ?? "",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                        ],
                      ),
                      Divider(endIndent: 50, indent: 50),
                      Text(
                        "Zen Products list".toLn(),
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Product title:".toLn(),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  item.data?.title ?? "",
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
                                  "Product coin amount:".toLn(),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "\$${item.data?.coin ?? 0}".toLn(),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            UiHelper.buttonMain2(
                              () async {
                                if (item.data != null) {
                                  context.to(
                                    DetailShopProductPage(data: item.data!),
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
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
