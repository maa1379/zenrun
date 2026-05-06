import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/PrefHelper/PrefHelpers.dart';
import 'package:zenrun/core/widgets/dialog_view.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/core/widgets/restart_widget.dart';
import 'package:zenrun/src/profile_pages/pages/subscription_page.dart';
import 'package:zenrun/src/profile_pages/pages/terms_page.dart';
import 'package:zenrun/src/profile_pages/pages/wallet_page.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';

import '../../../core/widgets/Costance.dart';
import '../../../core/widgets/custom_sacffold.dart';
import '../../../plugins/bmi/input_page/input_page.dart';
import 'about_us_page.dart';
import 'basket_history_page.dart';
import 'contact_us_page.dart';
import 'edit_profile_screen.dart';
import 'my_coin_page.dart';

class ProfileSettingPage extends StatefulWidget {
  const ProfileSettingPage({super.key});

  @override
  State<ProfileSettingPage> createState() => _ProfileSettingPageState();
}

class _ProfileSettingPageState extends State<ProfileSettingPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "Settings",
      body: ListView(
        padding: EdgeInsets.only(top: 10),
        children: [
          SettingsItem(
            title: "Edit account",
            onTap: () => context.to(EditProfileScreen()),
          ),
          SettingsItem(
            title: "Subscription",
            onTap: () => context.to(const SubscriptionPage()),
          ),
          SettingsItem(title: "My BMI", onTap: () => context.to(InputPage())),
          Column(
            children: [
              SizedBox(
                height: 5.h,
                width: 100.w,
                child: Row(
                  children: [
                    Gap(20),
                    Text(
                      "Private account".toLn(),
                      style: TextStyle(fontSize: 14),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Consumer<ProfileProvider>(
                        builder: (context, provider, _) {
                          return Transform.scale(
                            scale: .9,
                            child: CupertinoSwitch(
                              activeTrackColor: ColorsHelper.btn1,
                              value: provider.profile?.isPrivate ?? false,
                              onChanged: (value) async {
                                provider.profile?.isPrivate = value;
                                await provider.setProfile(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: ColorsHelper.btn1),
            ],
          ),
          SettingsItem(
            title: "My wallet",
            onTap: () => context.to(WalletPage()),
          ),
          SettingsItem(
            title: "My Coins",
            onTap: () => context.to(MyCoinPage()),
          ),
          SettingsItem(
            title: "Cart history",
            onTap: () {
              context.to(BasketHistoryPage());
            }, // Add action if needed
          ),
          SettingsItem(
            title: "Contact Us",
            onTap: () => context.to(ContactUsPage()),
          ),
          SettingsItem(
            title: "About Us",
            onTap: () => context.to(AboutUsPage()),
          ),
          SettingsItem(
            title: "Terms & Policy",
            onTap: () => context.to(TermsPage()),
          ),
          SettingsItem(
            title: "Exit from account",
            textColor: Colors.red,
            trailing: Icon(Icons.exit_to_app, size: 20, color: Colors.red),
            onTap: () async {
              DialogView.showDanger(
                context,
                "Do you want to exit the app?",
                "",
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  RestartAppWidget.restartApp(this.context);
                },
              );
            },
          ),
          SettingsItem(
            title: "Delete account",
            textColor: Colors.red,
            trailing: Icon(Icons.exit_to_app, size: 20, color: Colors.red),
            onTap: () {
              DialogView.showDanger(
                context,
                "Do you want to delete your account?",
                "",
                () async {
                  await PrefHelpers.removeUser();
                  await PrefHelpers.removeCartModelDb();
                  await PrefHelpers.removeProfile();
                  RestartAppWidget.restartApp(this.context);
                },
              );
            },
          ),
          Gap(10.h),
        ],
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? textColor;

  const SettingsItem({
    super.key,
    required this.title,
    this.onTap,
    this.trailing,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 5.h,
          width: 100.w,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Gap(20),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? Colors.black,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                trailing ??
                    Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                Gap(10),
              ],
            ),
          ),
        ),
        Divider(color: ColorsHelper.btn1),
      ],
    );
  }
}
