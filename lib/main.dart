import 'dart:async';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
// import 'package:telegram_web_app/telegram_web_app.dart' show TelegramWebApp;
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/services/get_profile_service.dart';
import 'package:zenrun/src/ai_pages/providers/ai_provider.dart';
import 'package:zenrun/src/auth_pages/pages/splash_page.dart';
import 'package:zenrun/src/auth_pages/providers/auth_provider.dart';
import 'package:zenrun/src/home_pages/providers/main_provider.dart';
import 'package:zenrun/src/home_pages/providers/pedometer_service.dart';
import 'package:zenrun/src/home_pages/providers/task_provider.dart';
import 'package:zenrun/src/profile_pages/providers/coin_provider.dart';
import 'package:zenrun/src/profile_pages/providers/comment_provider.dart';
import 'package:zenrun/src/profile_pages/providers/like_provider.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';
import 'package:zenrun/src/profile_pages/providers/subscription_provider.dart';
import 'package:zenrun/src/profile_pages/providers/wallet_provider.dart';
import 'package:zenrun/src/shop_pages/providers/basket_provider.dart';
import 'package:zenrun/src/shop_pages/providers/shop_provider.dart';
import 'package:zenrun/src/social_pages/providers/social_provider.dart';

// import 'package:telegram_web_app/telegram_web_app.dart' as tg;

import 'core/PrefHelper/PrefHelpers.dart';
import 'core/widgets/Costance.dart';
import 'core/widgets/restart_widget.dart';
import 'firebase_options.dart';
import 'get_page.dart';
import 'src/home_pages/providers/quiz_provider.dart';
import 'src/profile_pages/providers/shop_product_provider.dart';

final navKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Stripe — replace with your publishable key from https://dashboard.stripe.com/test/apikeys
  // Stripe.publishableKey = 'pk_test_51RhHnBBV8sQxphGUfXqCFyB0IHtiIwOPYAgAdqjGfQmHIVvP3zBW69sMPFODXFV9wPDnw8hkMaEmIoPiZjPuQ8lq00HLxxuTa2';
  // Stripe.merchantIdentifier = 'merchant.ai.zenrun.app';
  // await Stripe.instance.applySettings();
  await ToLn.init(baseLocale: 'en');
  await GetStorage.init();
  await FastCachedImageConfig.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if(await PrefHelpers.getUser() != null){
    await Get.putAsync(() => GetProfileService().init());
  }

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: false,
    androidStopForegroundOnPause: true,
    androidResumeOnClick: false,
    androidShowNotificationBadge: true,
  );

  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // tg.BackButton get backButton => TelegramWebApp.instance.backButton;

  void _setupEventListeners() {
    if (kIsWeb) {
      try {
        // if(TelegramWebApp.instance.isSupported){
        //   TelegramWebApp.instance.ready();
        //   TelegramWebApp.instance.expand();
        //   TelegramWebApp.instance.disableVerticalSwipes();
        //   TelegramWebApp.instance.lockOrientation();
        //   TelegramWebApp.instance.backButton.show();
        //   backButton.onClick(onButtonPress);
        //   TelegramWebApp.instance.setBackgroundColor(ColorsHelper.white);
        // }
      } catch (e) {
        print('Error initializing Mini App: $e');
      }
    }
  }

  @override
  void initState() {
    _setupEventListeners();
    super.initState();
  }



  @override
  void dispose() {

    super.dispose();
    if (kIsWeb) {
      // backButton.offClick(onButtonPress);
    }
  }

  void onButtonPress() {
    final snackBar = SnackBar(content: Text('Button pressed'.toLn()));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<HealthData>(create: (_) => HealthData()),
          ChangeNotifierProvider<TaskProvider>(create: (_) => TaskProvider()),
          ChangeNotifierProvider<ShopProductProvider>(
            create: (_) => ShopProductProvider(),
          ),
          ChangeNotifierProvider<MainProvider>(create: (_) => MainProvider()),
          ChangeNotifierProvider<LikeProvider>(create: (_) => LikeProvider()),
          ChangeNotifierProvider<QuizProvider>(create: (_) => QuizProvider()),
          ChangeNotifierProvider<SocialProvider>(
            create: (_) => SocialProvider(),
          ),
          ChangeNotifierProvider<AiProvider>(create: (_) => AiProvider()),
          ChangeNotifierProvider<CoinProvider>(create: (_) => CoinProvider()),
          ChangeNotifierProvider<ShopProvider>(create: (_) => ShopProvider()),
          ChangeNotifierProvider<WalletProvider>(
            create: (_) => WalletProvider(),
          ),
          ChangeNotifierProvider<SubscriptionProvider>(
            create: (_) => SubscriptionProvider(),
          ),
          ChangeNotifierProvider<BasketProvider>(
            create: (_) => BasketProvider(),
          ),
          ChangeNotifierProvider<CommentProvider>(
            create: (_) => CommentProvider(),
          ),
          ChangeNotifierProvider<ProfileProvider>(
            create: (_) => ProfileProvider(),
          ),
        ],
        child: Sizer(
          maxMobileWidth: MediaQuery.of(context).size.width * .3,
          builder: (context, orientation, deviceType) {
            return RestartAppWidget(
              child: SafeArea(
                child: GetMaterialApp(
                  getPages: getPages,
                  title: "ZenRun",
                  navigatorKey: navKey,
                  themeMode: ThemeMode.light,
                  debugShowCheckedModeBanner: false,
                  home: const SplashPage(),
                  builder: EasyLoading.init(),
                  theme: ThemeHelper.themeData(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


