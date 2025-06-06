import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/provider/revenue_cat_provider.dart';

/// Service to handle feature restrictions based on user entitlement
class FeatureRestrictionService {
  static const List<String> _majorScaleNames = [
    'Ionian',
    'Dorian', 
    'Phrygian',
    'Lydian',
    'Mixolydian',
    'Aeolian',
    'Locrian'
  ];

  /// Returns true if user can access a specific scale
  static bool canAccessScale(String scaleName, Entitlement entitlement) {
    if (entitlement.hasFullScaleAccess) {
      return true;
    }
    
    // Free users can only access major scales (diatonic modes)
    return _majorScaleNames.contains(scaleName);
  }

  /// Returns list of scales available to user based on entitlement
  static List<String> getAvailableScales(List<String> allScales, Entitlement entitlement) {
    if (entitlement.hasFullScaleAccess) {
      return allScales;
    }
    
    // Free users get only major scales
    return allScales.where((scale) => _majorScaleNames.contains(scale)).toList();
  }

  /// Returns true if user can download fretboard images
  static bool canDownloadFretboard(Entitlement entitlement) {
    return entitlement.canDownloadFretboard;
  }

  /// Returns true if user can use audio/player features
  static bool canUseAudioFeatures(Entitlement entitlement) {
    return entitlement.hasAudioAccess;
  }

  /// Returns true if user should see ads
  static bool shouldShowAds(Entitlement entitlement) {
    return entitlement.showAds;
  }

  /// Get upgrade message for a restricted feature
  static String getUpgradeMessage(String featureName) {
    return 'Upgrade to Premium to access $featureName';
  }

  /// Get scale restriction message
  static String getScaleRestrictionMessage() {
    return 'Upgrade to Premium to access all scales. Free users can only use major scales.';
  }

  /// Get fretboard download restriction message
  static String getFretboardDownloadRestrictionMessage() {
    return 'Upgrade to Premium to download fretboard images';
  }

  /// Get audio feature restriction message
  static String getAudioRestrictionMessage() {
    return 'Upgrade to Premium to use audio playback features';
  }
}

/// Provider for easy access to feature restrictions throughout the app
final featureRestrictionProvider = Provider.family<bool, String>((ref, feature) {
  final entitlement = ref.watch(revenueCatProvider);
  
  switch (feature) {
    case 'fretboard_download':
      return FeatureRestrictionService.canDownloadFretboard(entitlement);
    case 'audio_features':
      return FeatureRestrictionService.canUseAudioFeatures(entitlement);
    case 'show_ads':
      return FeatureRestrictionService.shouldShowAds(entitlement);
    case 'full_scale_access':
      return entitlement.hasFullScaleAccess;
    default:
      return false;
  }
});

/// Provider for available scales based on user entitlement
final availableScalesProvider = Provider.family<List<String>, List<String>>((ref, allScales) {
  final entitlement = ref.watch(revenueCatProvider);
  return FeatureRestrictionService.getAvailableScales(allScales, entitlement);
});