enum Entitlement {
  free,           // Free tier, major scales only
  premiumSub,     // Monthly subscription (in-app or riffroutine.com): all features + cloud library
  premiumOneTime, // Lifetime purchase: scales, audio, download (NO instruments, NO cloud library)
}

extension EntitlementExtensions on Entitlement {
  /// Returns true if user has any premium features (subscription or lifetime)
  bool get isPremium =>
      this == Entitlement.premiumSub ||
      this == Entitlement.premiumOneTime;

  /// Returns true if user is an active subscriber (monthly in-app or riffroutine.com)
  bool get isSubscriber => this == Entitlement.premiumSub;

  /// Returns true if user can access all scales
  bool get hasFullScaleAccess => isPremium;

  /// Returns true if user can download fretboard images
  bool get canDownloadFretboard => isPremium;

  /// Returns true if user can use audio player features
  bool get hasAudioAccess => isPremium;

  /// Returns true if user can access the fingerings library (subscribers only)
  bool get hasFingeringsLibraryAccess => isSubscriber;

  /// Returns true if user is a lifetime purchaser
  bool get isLifetime => this == Entitlement.premiumOneTime;
}
