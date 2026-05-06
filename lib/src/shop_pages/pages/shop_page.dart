import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/models/shop_product_model.dart';
import 'package:zenrun/src/shop_pages/pages/product_list_page.dart';
import 'package:zenrun/src/shop_pages/pages/sub_category_page.dart';
import 'package:zenrun/src/shop_pages/providers/shop_provider.dart';

import '../../../generated/assets.dart';
import 'detail_shop_product_page.dart';
import 'package:toln/toln.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  @override
  void initState() {
    super.initState();
    // استفاده از addPostFrameCallback برای جلوگیری از خطای بیلد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().init();
    });
  }

  bool checkIsDiscount(ShopProductModel data) {
    return data.coinTakhfif != data.coin;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, provider, child) {
        if (provider.shopProductList.isEmpty && !provider.loading) {
          // اگر لیست خالیه ولی هنوز لودینگ فالس نشده یعنی شروع نشده
          return UiHelper.showLoading();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.init();
          },
          child: Container(
            height: 100.h,
            width: 100.w,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesImg4),
                fit: BoxFit.cover,
              ),
            ),
            child: (!provider.loading)
                ? UiHelper.showLoading()
                : CustomScrollView(
              slivers: [
                const SliverGap(15),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 32.h,
                    width: 100.w,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Text(
                              "Zen Products".toLn(),
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                        ),
                        const Gap(15),
                        Expanded(
                          child: ListView.builder(
                            itemCount: provider.shopProductList.length,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            itemBuilder: (context, index) {
                              final item = provider.shopProductList[index];
                              return _buildShopProductItem(item);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverGap(15),
                SliverToBoxAdapter(
                  child: Divider(
                    color: ColorsHelper.btn1,
                    endIndent: 30,
                    indent: 30,
                  ),
                ),
                const SliverGap(15),
                SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        "Categories".toLn(),
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SliverGap(15),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  sliver: SliverGrid.builder(
                    itemCount: provider.categoryList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2 / 2.9,
                    ),
                    itemBuilder: (context, index) {
                      final item = provider.categoryList[index];
                      return GestureDetector(
                        onTap: () {
                          if (item.subList.isEmpty) {
                            context.to(
                              ProductListPage(
                                data: provider.productList
                                    .where((element) => element.categoryId == item.id)
                                    .toList(),
                              ),
                            );
                          } else {
                            context.to(SubCategoryPage(data: item));
                          }
                        },
                        child: Column(
                          children: [
                            Container(
                              height: 14.h,
                              decoration: BoxDecoration(
                                border: Border.all(color: ColorsHelper.btn2),
                                borderRadius: UiHelper.borderRadius16,
                                image: DecorationImage(
                                  image: FastCachedImageProvider(item.image ?? ""),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const Gap(5),
                            Text(
                              item.title ?? "",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SliverGap(20),
              ],
            ),
          ),
        );
      },
    );
  }

  // اکسترکت کردن ویجت برای خوانایی بهتر
  Widget _buildShopProductItem(ShopProductModel item) {
    return Container(
      width: 35.w,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: ColorsHelper.btn2),
        borderRadius: UiHelper.borderRadius16,
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: FastCachedImage(
                url: item.image ?? "",
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const Gap(5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              item.title ?? "",
              style: const TextStyle(color: Colors.black, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            children: [
              Text(
                "${item.coin} Coins".toLn(),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  decoration: !checkIsDiscount(item) ? null : TextDecoration.lineThrough,
                ),
              ),
              if (checkIsDiscount(item))
                Text(
                  "${item.coinTakhfif} Coins".toLn(),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const Gap(5),
          UiHelper.buttonMain2(
                () async {
              context.to(DetailShopProductPage(data: item));
            },
            "Buy",
            width: 30.w,
            height: 4.h,
            fontSize: 14,
          ),
          const Gap(10),
        ],
      ),
    );
  }
}