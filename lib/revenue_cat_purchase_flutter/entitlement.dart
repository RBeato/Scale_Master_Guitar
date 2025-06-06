enum Entitlement { 
  free,           // Free with ads, major scales only, no fretboard download
  premiumSub,     // Subscription: no ads, full functionality
  premiumOneTime  // One-time purchase: no ads, full functionality
}

extension EntitlementExtensions on Entitlement {
  /// Returns true if user has any premium features (subscription or one-time)
  bool get isPremium => this == Entitlement.premiumSub || this == Entitlement.premiumOneTime;
  
  /// Returns true if user should see ads
  bool get showAds => this == Entitlement.free;
  
  /// Returns true if user can access all scales
  bool get hasFullScaleAccess => isPremium;
  
  /// Returns true if user can download fretboard images
  bool get canDownloadFretboard => isPremium;
  
  /// Returns true if user can use audio player features
  bool get hasAudioAccess => isPremium;
}
