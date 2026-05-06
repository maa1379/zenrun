import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/models/product_model.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';

import '../../../generated/assets.dart';
import 'detail_product_page.dart';
import 'package:toln/toln.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, required this.data});

  final List<ProductModel> data;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelper.appBar("Products"),
      body: Container(
        height: 100.h,
        width: 100.w,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.imagesImg4),
            fit: BoxFit.cover,
          ),
        ),
        child: (widget.data.isEmpty)
            ? Center(
                child: Text(
                  "Empty".toLn(),
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            : Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  final hasSubscription =
                      profileProvider.profile?.hasActiveSubscription ?? false;
                  return GridView.builder(
                    itemCount: widget.data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2 / 2.8,
                    ),
                    itemBuilder: (context, index) {
                      final item = widget.data[index];
                      return GestureDetector(
                        onTap: () {
                          context.to(
                            DetailProductPage(
                              data: item,
                              isPaid: hasSubscription ? true : null,
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: ColorsHelper.btn2),
                            borderRadius: UiHelper.borderRadius16,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 10,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    item.images.first,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  spacing: 5,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: Text(
                                        item.title ?? "",
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      hasSubscription
                                          ? "Free".toLn()
                                          : "\$${item.priceTakhfif}".toLn(),
                                      style: TextStyle(
                                        color: hasSubscription
                                            ? ColorsHelper.btn1
                                            : Colors.black,
                                        fontSize: 14,
                                        fontWeight: hasSubscription
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    UiHelper.buttonMain2(
                                      () {
                                        context.to(
                                          DetailProductPage(
                                            data: item,
                                            isPaid: hasSubscription ? true : null,
                                          ),
                                        );
                                      },
                                      hasSubscription ? "Get Free" : "Buy",
                                      width: 30.w,
                                      height: 4.h,
                                      fontSize: 14,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
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
