import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:test/UI/fretboard_page/provider/fretboard_page_fingerings_provider.dart';
import 'package:test/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

import '../../revenue_cat_purchase_flutter/entitlement.dart';
import '../player_page/provider/player_page_title.dart';
import 'fretboard_full.dart';

class FretboardPage extends ConsumerWidget {
  const FretboardPage({super.key});

  prohibitScreenShots(Entitlement entitlement) {
    if (entitlement == Entitlement.free) {
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final entitlement = ref.watch(revenueCatProvider);

    //TODO: Revert this
    final entitlement = Entitlement.premium;

    prohibitScreenShots(entitlement);
    // Obtain a copy of ChordScaleFingeringsModel specific to this page
    final fretboardFingerings = ref.watch(fretboardPageFingeringsProvider);

    return WillPopScope(
      onWillPop: () {
        Navigator.of(context).pop();
        return Future.value(true);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: Colors.grey[800],
          title: const PlayerPageTitle(),
        ),
        body: FretboardFull(fingeringsModel: fretboardFingerings),
      ),
    );
  }
}
