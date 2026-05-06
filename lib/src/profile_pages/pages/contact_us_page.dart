import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenrun/src/auth_pages/providers/auth_provider.dart';

import '../../../core/widgets/Costance.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  AuthProvider authProvider = AuthProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsHelper.white,
      appBar: UiHelper.appBar("Contact Us"),
      body: SizedBox(
        height: 100.h,
        width: 100.w,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            children: [
              Text(
                authProvider.contactUs?.description ?? "",
                style: TextStyle(fontFamily: 'IRANSans', fontSize: 12),
              ),
              const SizedBox(height: 30),

              // Instagram
              CustomIconButton(
                icon: FontAwesomeIcons.instagram,
                text:
                    authProvider.contactUs?.instagram?.replaceAll('@', '') ?? "",
                onPressed: () {
                  final instagramUrl =
                      'https://instagram.com/${authProvider.contactUs?.instagram?.replaceAll('@', '')}';
                  launchUrl(
                    Uri.parse(instagramUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),

              const SizedBox(height: 15),
              // WhatsApp
              CustomIconButton(
                icon: FontAwesomeIcons.whatsapp,
                text: authProvider.contactUs?.whatsapp?.replaceAll('@', '') ?? "",
                onPressed: () {
                  final whatsappNumber = authProvider.contactUs?.whatsapp
                      ?.replaceAll('@', '')
                      .replaceAll(' ', '');
                  final whatsappUrl = 'https://wa.me/$whatsappNumber';
                  launchUrl(
                    Uri.parse(whatsappUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              const SizedBox(height: 15),
              // Telegram
              CustomIconButton(
                icon: FontAwesomeIcons.telegram,
                text: authProvider.contactUs?.telegram?.replaceAll('@', '') ?? "",
                onPressed: () {},
              ),
              const SizedBox(height: 15),
              // youtube
              CustomIconButton(
                icon: FontAwesomeIcons.youtube,
                text: authProvider.contactUs?.youtube ?? "",
                onPressed: () {
                  launchUrl(Uri.parse(authProvider.contactUs?.youtube ?? ""));
                },
              ),
              const SizedBox(height: 15),
              // phone
              CustomIconButton(
                icon: FontAwesomeIcons.phone,
                text: authProvider.contactUs?.telephone ?? "",
                onPressed: () {
                  // launchUrl(Uri.parse(authProvider.contactUs?.telephone ?? ""));
                },
              ),
              const SizedBox(height: 15),
              // Fax
              CustomIconButton(
                icon: FontAwesomeIcons.fax,
                text: authProvider.contactUs?.fax ?? "",
                onPressed: () {
                  //launchUrl(Uri.parse(authProvider.contactUs?.address));
                },
              ),
              const SizedBox(height: 15),
              // Mail
              CustomIconButton(
                icon: FontAwesomeIcons.earthEurope,
                text: authProvider.contactUs?.site ?? "",
                onPressed: () {
                  launchUrl(Uri.parse(authProvider.contactUs?.site ?? ""));
                },
              ),
              const SizedBox(height: 15),
              // Address
              CustomIconButton(
                icon: FontAwesomeIcons.addressCard,
                text: authProvider.contactUs?.address ?? "",
                onPressed: () {
                  //launchUrl(Uri.parse(authProvider.contactUs?.address));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onPressed,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade500),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ColorsHelper.btn1,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(15),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  height: 32,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
