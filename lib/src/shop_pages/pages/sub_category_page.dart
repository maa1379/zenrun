import 'package:auto_size_text/auto_size_text.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/models/category_model.dart';
import 'package:zenrun/src/shop_pages/pages/product_list_page.dart';
import 'package:zenrun/src/shop_pages/providers/shop_provider.dart';

import '../../../generated/assets.dart';
import '../providers/basket_provider.dart';

class SubCategoryPage extends StatefulWidget {
  const SubCategoryPage({super.key, required this.data});

  final CategoryModel data;

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelper.appBar(widget.data.title ?? ""),
      body: Consumer<ShopProvider>(
        builder: (context, provider, child) {
          return Container(
            height: 100.h,
            width: 100.w,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesImg4),
                fit: BoxFit.cover,
              ),
            ),
            child: (widget.data.subList.isEmpty)
                ? Center(
                    child: Text(
                      "Empty".toLn(),
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: GridView.builder(
                      itemCount: widget.data.subList.length,
                      addAutomaticKeepAlives: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 25.h,
                      ),
                      itemBuilder: (context, index) {
                        final item = widget.data.subList[index];
                        return GestureDetector(
                          onTap: () {
                            context.to(
                              ProductListPage(
                                data: provider.productList
                                    .where(
                                      (element) =>
                                          element.subCategoryId == item.id,
                                    )
                                    .toList(),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 100.w,
                                height: 15.h,
                                padding: EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  border: Border.all(color: ColorsHelper.btn2),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  spacing: 5,
                                  children: [
                                    Expanded(
                                      child: FastCachedImage(
                                        url:item.image ?? "",
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        item.title ?? "",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 5.h,
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
                                      for (var i
                                          in provider.productList
                                              .where(
                                                (element) =>
                                                    element.subCategoryId ==
                                                    item.id,
                                              )
                                              .toList()) {
                                        await context
                                            .read<BasketProvider>()
                                            .addProductToDb(i, 1, context);
                                      }
                                      ViewHelper.showSuccessDialog(context, "Product added to cart");
                                    },
                                    borderRadius: BorderRadius.only(
                                      bottomRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                    child: Center(
                                      child: AutoSizeText(
                                        "Buy all Season",
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
                    ),
                  ),
          );
        },
      ),
    );
  }
}
