import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/UI/fretboard_page/provider/fretboard_page_fingerings_provider.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/constants/app_theme.dart';
import 'package:scalemasterguitar/widgets/banner_ad_widget.dart';
import 'package:scalemasterguitar/services/in_app_review_service.dart';

import '../../revenue_cat_purchase_flutter/entitlement.dart';
import '../player_page/provider/player_page_title.dart';
import 'fretboard_full.dart';

class FretboardPage extends ConsumerWidget {
  const FretboardPage({super.key});

  void prohibitScreenShots(Entitlement entitlement) {
    // Screen capture prevention has been removed as it required flutter_windowmanager
    // Consider alternative approaches for premium features
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(revenueCatProvider);

    prohibitScreenShots(entitlement);
    // Track scale exploration as a positive action
    InAppReviewService().trackKeyAction();

    // Obtain a copy of ChordScaleFingeringsModel specific to this page
    final fretboardFingerings = ref.watch(fretboardPageFingeringsProvider);

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: AppColors.background,
          title: const PlayerPageTitle(),
        ),
        bottomNavigationBar: const BannerAdWidget(),
        body: FretboardFull(fingeringsModel: fretboardFingerings),
      );
  }
}
