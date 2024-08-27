import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/drawer/provider/settings_state_notifier.dart';
import 'package:test/UI/home_page/home_page.dart';
import 'package:logger/logger.dart';
import 'package:test/revenue_cat_purchase_flutter/purchase_api.dart';
import 'UI/fretboard/provider/fingerings_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'revenue_cat_purchase_flutter/store_config.dart';

//TODO: 7-day trial setup on Google Play console and RevenueCat, check chatGPT
//TODO: Drawer preferences bug
//TODO: Dropdown bug. Scale dropdown bug. It is not rebuilding properly because it is being assigned the same value as initially set. But the UI is changing to a new value
//TODO: Sound Drawer change not immediately reflected
//TODO: Review trial detection and entitlements
//TODO: Use Restore Purchases Button
//!TODO: Use physical device
//TODO: Check all scales

//RevenueCat tutorial: https://www.youtube.com/watch?v=3w15dLLi-K8&t=576s
//REvenueCat updated: https://www.youtube.com/watch?v=31mM8ozGyE8&t=403s
//!go to 20:00

//FROM REVENUECAT ON OFFERINGS:
// final offerings = await Purchases.getOfferings();
// final current = offerings.current;
// if (current != null) {
//   final showNewBenefits = current.metadata["show_new_benefits"];
//   final title = (current.metadata["title_strings"] as Map<String, Object>?)?["en_US"];
//   final cta = (current.metadata["cta_strings"] as Map<String, Object>?)?["en_US"];

final logger = Logger();

void main() async {
  try {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    await dotenv.load(fileName: ".env");

    // await PurchaseApi.init(); //!use emulator with playstore activated

    // if (Platform.isIOS || Platform.isMacOS) {
    //   StoreConfig(
    //     store: StoreChoice.appleStore,
    //     apiKey: dotenv.env['APPLE_API_KEY']!,
    //   );
    // } else if (Platform.isAndroid) {
    //   StoreConfig(
    //       store: StoreChoice.googlePlay, apiKey: dotenv.env['GOOGLE_API_KEY']!);
    // }

    final container = ProviderContainer();
    await container.read(settingsStateNotifierProvider.notifier).settings;
    await container.read(chordModelFretboardFingeringProvider.future);

    FlutterNativeSplash.remove();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).then((_) {
      runApp(
          // DevicePreview(
          //   enabled: !kReleaseMode,
          //   builder: (context) => const
          const ProviderScope(child: MyApp())
          // )
          );
    });
  } catch (error, stackTrace) {
    logger.e('Setup has failed', error, stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      // locale: DevicePreview.locale(context),s
      // builder: DevicePreview.appBuilder,
      title: 'Scale Master Guitar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: const HomePage(title: 'Scale Master Guitar'),
    );
  }
}
