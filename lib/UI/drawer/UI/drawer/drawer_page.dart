import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
<<<<<<< HEAD
import 'package:scalemasterguitar/UI/drawer/UI/drawer/sounds_dropdown_column.dart';
import 'package:scalemasterguitar/UI/drawer/provider/settings_state_notifier.dart';
import 'package:scalemasterguitar/constants/styles.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/paywall_page.dart';
=======
import 'package:test/UI/drawer/UI/drawer/sounds_dropdown_column.dart';
import 'package:test/UI/drawer/provider/settings_state_notifier.dart';
import 'package:test/constants/styles.dart';
import 'package:test/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:test/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';
import 'package:test/revenue_cat_purchase_flutter/paywall_page.dart';
import 'package:test/ads/banner_ad_widget.dart';
>>>>>>> dev
import 'chord_options_cards.dart';

class DrawerPage extends ConsumerStatefulWidget {
  const DrawerPage({super.key});

  @override
  ConsumerState<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends ConsumerState<DrawerPage> {
  @override
  Widget build(BuildContext context) {
    // final entitlement = ref.watch(revenueCatProvider);
    //TODO: Revert this
    final entitlement = Entitlement.premium;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            children: <Widget>[
              GeneralOptions(),
              SoundsDropdownColumn(),
            ],
          ),
          Column(
            children: [
              if (entitlement != Entitlement.premium)
                ElevatedButton.icon(
                  icon: const Icon(Icons.star, color: Colors.yellow),
                  label: const Text('Upgrade to Premium'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.yellow,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PaywallPage()));
                  },
                ),
              const SizedBox(height: 20),
              const BannerAdWidget(),
              const SizedBox(height: 20),
              InkWell(
                highlightColor: cardColor,
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(settingsStateNotifierProvider.notifier)
                        .resetValues();
                  },
                  child: Card(
                    color: clearPreferencesButtonColor,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Clear Preferences',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
