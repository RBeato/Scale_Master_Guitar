enum StoreChoice { appleStore, googlePlay }

class StoreConfig {
  final StoreChoice store;
  final String apiKey;

  StoreConfig._internal(this.store, this.apiKey);

  static StoreConfig? _instance;

  factory StoreConfig({required StoreChoice store, required String apiKey}) {
    _instance ??= StoreConfig._internal(store, apiKey);
    return _instance!;
  }

  static StoreConfig get instance {
    if (_instance == null) {
      throw Exception("StoreConfig is not initialized");
    }
    return _instance!;
  }

  static bool isForAppleStore() => instance.store == StoreChoice.appleStore;
  static bool isForGooglePlay() => instance.store == StoreChoice.googlePlay;
}
