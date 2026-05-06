import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/src/auth_pages/providers/auth_provider.dart';
import 'package:toln/toln.dart';

import '../../../generated/assets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey.shade50, // تم روشن و ملایم
        body: SizedBox(
          height: 100.h,
          width: 100.w,
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildLoginCard().animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                const Spacer(),
                _buildSocialMediaSection().animate().fadeIn(delay: 300.ms),
                Gap(3.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "ZenRun AI",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: IconButton(
              onPressed: () async {
                await launchUrl(
                  Uri.parse(context.read<AuthProvider>().contactUs?.whatsapp ?? ""),
                  mode: LaunchMode.externalApplication,
                );
              },
              icon: Image.asset(Assets.imagesSupport, width: 24, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Consumer<AuthProvider>(
      builder: (context, provider, child) {
        return Container(
          width: 88.w,
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Welcome Back!".toLn(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Gap(10),
              Text(
                "Sign in to continue your journey",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              Gap(4.h),
              _buildEmailTextField(),

              if (provider.isSend) ...[
                const Gap(15),
                _buildCodeTextField().animate().fadeIn().slideY(begin: -0.2, end: 0),
              ],

              Gap(4.h),
              _buildLoginButton(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmailTextField() {
    return TextField(
      controller: context.read<AuthProvider>().email,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      onChanged: (value) {
        if (context.read<AuthProvider>().isSend == true) {
          context.read<AuthProvider>().isSend = false;
          context.read<AuthProvider>().update();
        }
      },
      decoration: _inputDecoration(hint: "Email Address", icon: Icons.email_outlined),
    );
  }

  Widget _buildCodeTextField() {
    return TextField(
      keyboardType: TextInputType.number,
      controller: context.read<AuthProvider>().code,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 2),
      decoration: _inputDecoration(hint: "Verification Code", icon: Icons.lock_outline),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint.toLn(),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.blue.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildLoginButton(AuthProvider provider) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ColorsHelper.btn2,
        boxShadow: [
          BoxShadow(
            color: ColorsHelper.btn2.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (!provider.isSend) {
              provider.login(context);
            } else {
              provider.verifySms(context);
            }
          },
          child: Center(
            child: Text(
              provider.isSend ? "Verify & Login" : "Login",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    final provider = context.read<AuthProvider>();
    return Column(
      children: [
        Text(
          "Connect with us".toLn(),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Gap(15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(Assets.imagesYoutube, () async {
              await launchUrl(Uri.parse(provider.contactUs?.youtube ?? ""), mode: LaunchMode.externalApplication);
            }),
            const Gap(20),
            _socialButton(Assets.imagesInstagram, () async {
              await launchUrl(Uri.parse(provider.contactUs?.instagram ?? ""), mode: LaunchMode.externalApplication);
            }),
          ],
        ),
      ],
    );
  }

  Widget _socialButton(String asset, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Image.asset(asset, width: 24, height: 24),
      ),
    );
  }
}