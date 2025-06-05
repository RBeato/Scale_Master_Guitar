import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/utils/debug_overlay.dart';
import 'package:scalemasterguitar/UI/drawer/provider/settings_state_notifier.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/UI/home_page/home_page.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:logger/logger.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart';
import 'package:scalemasterguitar/services/ad_service.dart';
import 'UI/fretboard/provider/fingerings_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audio_session/audio_session.dart';

//TODO: fix performance. Avoid unnecessary rebuilds. Test overall performance
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
  // Set up error handling for the entire app
  FlutterError.onError = (details) {
    logger.e('Flutter error', 
      error: details.exception, 
      stackTrace: details.stack,
      time: DateTime.now()
    );
    FlutterError.presentError(details);
  };
  
  // Set up uncaught error handling
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Uncaught error', 
      error: error, 
      stackTrace: stack,
      time: DateTime.now()
    );
    return true;
  };
  
  // Set up zone for error handling
  runZonedGuarded(() async {
    try {
      // Ensure Flutter binding is initialized first
      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      
      // Configure audio session early
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        await session.setActive(true);
        
        // Handle audio interruptions
        session.interruptionEventStream.listen((event) {
          if (event.begin) {
            debugPrint('Audio session interrupted');
          } else {
            debugPrint('Audio session interruption ended');
            // Reactivate audio session after interruption
            session.setActive(true);
          }
        });
        
        // Handle audio device changes
        session.devicesChangedEventStream.listen((_) {
          debugPrint('Audio devices changed');
        });
        
        // Handle audio becoming noisy (e.g., headphones unplugged)
        session.becomingNoisyEventStream.listen((_) {
          debugPrint('Audio became noisy - pausing playback');
          // Pause playback when headphones are unplugged
        });
        
        debugPrint('Audio session configured successfully');
      } catch (e, stackTrace) {
        debugPrint('Error configuring audio session: $e');
        logger.e('Error configuring audio session', error: e, stackTrace: stackTrace);
      }
      
      // Load environment variables
      await dotenv.load(fileName: ".env");
      
      // Initialize Mobile Ads
      await MobileAds.instance.initialize();

      // Initialize RevenueCat
      if (Platform.isIOS || Platform.isMacOS) {
        await PurchaseApi.init(dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '');
      } else if (Platform.isAndroid) {
        await PurchaseApi.init(dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '');
      }
    
      // Audio session is already configured above, no need to configure it again

      final container = ProviderContainer();
      await container.read(settingsStateNotifierProvider.notifier).settings;
      await container.read(chordModelFretboardFingeringProvider.future);

      // Initialize AdMob with test devices
      final List<String> deviceIds = []; // Add your test device IDs here
      final configuration = RequestConfiguration(
        testDeviceIds: deviceIds,
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
    );
    MobileAds.instance.updateRequestConfiguration(configuration);
    await MobileAds.instance.initialize();
    
    // Check connectivity and initialize AdService
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('No internet connection');
      // Handle no internet scenario
    } else {
      await AdService().initialize();
    }

    FlutterNativeSplash.remove();
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    
    // Run the app
    runApp(ProviderScope(child: MyApp()));
    } catch (error, stackTrace) {
      logger.e('Setup has failed', error: error, stackTrace: stackTrace);
      // Handle the error appropriately, e.g., show an error dialog
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('An error occurred: ${error.toString()}'),
            ),
          ),
        ),
      );
    }
  }, (error, stackTrace) {
    logger.e('Zone error', error: error, stackTrace: stackTrace);
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

// Global flag to show debug overlay in TestFlight builds
bool showDebugOverlay = true;

class _MyAppState extends ConsumerState<MyApp> {
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _checkExistingPurchases();
  }

  Future<void> _checkExistingPurchases() async {
    try {
      await ref.read(revenueCatProvider.notifier).updatePurchaseStatus();
    } catch (e) {
      debugPrint('Error checking existing purchases: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUserSubscribed = ref.watch(revenueCatProvider);
    // Convert entitlement status to a Future<bool> for the FutureBuilder
    Future<bool> isSubscribed = Future.value(isUserSubscribed == Entitlement.premium);
    return FutureBuilder<bool>(
      future: isSubscribed,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        Widget app = MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Scale Master Guitar',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green[800] ?? Colors.green,
              brightness: Brightness.dark,
            ),
          ),
          home: ScaffoldMessenger(
            key: scaffoldMessengerKey,
            child: showDebugOverlay
                ? DebugOverlay(child: snapshot.data == true
                    ? const HomePage(title: 'Scale Master Guitar')
                    : const HomePage(title: 'Scale Master Guitar'))
                : (snapshot.data == true
                    ? const HomePage(title: 'Scale Master Guitar')
                    : const HomePage(title: 'Scale Master Guitar')),
          ),
        );
        
        return app;
      },
    );
  }
}
