import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/drawer/provider/settings_state_notifier.dart';
import 'package:test/UI/home_page/home_page.dart';
import 'package:logger/logger.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:test/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:test/revenue_cat_purchase_flutter/purchase_api.dart';
import 'package:test/revenue_cat_purchase_flutter/store_config.dart';
import 'UI/fretboard/provider/fingerings_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

//TODO: fix too many beats error in the player. when trashing set beat counter to 0.
//TODO: add the google store key from old project to this one

//Create paywall manually ... Have restore logic and button for that.
//TODO: 7-day trial setup on Google Play console and RevenueCat, check chatGPT
//TODO: Dropdown bug. Scale dropdown bug. It is not rebuilding properly because it is being assigned the same value as initially set. But the UI is changing to a new value
//TODO: Review trial detection and entitlements
//!TODO: Use physical device
//TODO: fix blues and major blues chord names, probably being indexed from 0 to 5 and leaving 6 out. should be leaving out the passing tone

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
    MobileAds.instance.initialize();

    //TODO: Revert this
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

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('No internet connection');
      // Handle no internet scenario
    } else {
      // await PurchaseApi.init();
    }

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
    logger.e('Setup has failed', error: error, stackTrace: stackTrace);
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    //TODO: Revert this
    // _checkExistingPurchases();
  }

  Future<void> _checkExistingPurchases() async {
    try {
      await ref.read(revenueCatProvider.notifier).updatePurchaseStatus();
    } catch (e) {
      debugPrint("Error checking existing purchases: $e");
    }
  }

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
