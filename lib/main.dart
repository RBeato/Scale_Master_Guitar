// import 'dart:nativewrappers/_internal/vm/lib/developer.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/UI/drawer/provider/settings_state_notifier.dart';
import 'package:test/UI/home_page/home_page.dart';
import 'package:logger/logger.dart';
// import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'UI/fretboard/provider/fingerings_provider.dart';

import 'UI/home_page/selection_page.dart';

//TODO: 7-day trial setup on Google Play console and RevenueCat, check chatGPT
//TODO: Single payment of 2.99

//Revenue Cat tutorial: https://www.youtube.com/watch?v=3w15dLLi-K8&t=576s

final logger = Logger();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    // await _configureSubscription();

    // Await the settings from the provider
    final settings =
        await container.read(settingsStateNotifierProvider.notifier).settings;
    print(settings); // Debugging purpose

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

// Future<void> _configureSubscription() async {
//   await dotenv.load(fileName: ".env");

//   await Purchases.setLogLevel(LogLevel.debug);
//   PurchasesConfiguration? configuration;

//   if (Platform.isIOS || Platform.isMacOS) {
//     // StoreConfig(
//     //   store: Store.appStore,
//     //   apiKey: dotenv.env['APPLE_API_KEY']!,
//     // );
//     configuration = PurchasesConfiguration(
//       dotenv.env['APPLE_APP_USER_ID']!,
//     );
//   } else if (Platform.isAndroid) {
//     // Run the app passing --dart-define=AMAZON=true
//     // const useAmazon = bool.fromEnvironment("amazon");
//     // StoreConfig(
//     //   store: useAmazon ? Store.amazon : Store.playStore,
//     //   apiKey: useAmazon
//     //       ? dotenv.env['AMAZON_API_KEY']!
//     //       : dotenv.env['GOOGLE_API_KEY']!,
//     // );
//     configuration = PurchasesConfiguration(dotenv.env['GOOGLE_API_KEY']!);
//   }
//   // Initialize RevenueCat
//   // // await Purchases.setup(dotenv.env['VAR_NAME']!);
//   if (configuration != null) {
//     await Purchases.configure(configuration);

//     // Check Subscription Status
//     bool hasActiveSubscription = await _checkSubscriptionStatus();

//     if (hasActiveSubscription) {
//       log('User has an active subscription or trial.');
//       // Proceed with providing premium access
//     } else {
//       log('User does not have an active subscription or trial.');
//       // Show paywall or limit access
//       final paywallResult =
//           await RevenueCatUI.presentPaywallIfNeeded("premium");
//       log('Paywall result: $paywallResult');
//     }
//   }
// }

// Future<bool> _checkSubscriptionStatus() async {
//   try {
//     CustomerInfo customerInfo = await Purchases.getCustomerInfo();
//     if (customerInfo.activeSubscriptions.isNotEmpty) {
//       // User has an active subscription or trial
//       return true;
//     } else {
//       // User does not have an active subscription or trial
//       return false;
//     }
//   } on PlatformException catch (e) {
//     // Handle error
//     log('Error fetching subscription status: ${e.message}');
//     return false;
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // showPerformanceOverlay: true,
      useInheritedMediaQuery: true,
      // locale: DevicePreview.locale(context),s
      // builder: DevicePreview.appBuilder,
      title: 'Scale Master Guitar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home:
          // const SelectionPage(),
          const HomePage(title: 'Scale Master Guitar'),
    );
  }
}
