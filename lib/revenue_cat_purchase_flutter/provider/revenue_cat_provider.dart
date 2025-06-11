import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/entitlement.dart';
import 'package:scalemasterguitar/revenue_cat_purchase_flutter/purchase_api.dart';

// Define a provider for RevenueCatNotifier
final revenueCatProvider =
    StateNotifierProvider<RevenueCatNotifier, Entitlement>((ref) {
  return RevenueCatNotifier(ref);
});

// Testing state provider
final testingStateProvider = StateNotifierProvider<TestingStateNotifier, TestingState>((ref) {
  return TestingStateNotifier();
});

class TestingState {
  final bool isEnabled;
  final Entitlement testEntitlement;
  
  const TestingState({
    this.isEnabled = false,
    this.testEntitlement = Entitlement.free,
  });
  
  TestingState copyWith({
    bool? isEnabled,
    Entitlement? testEntitlement,
  }) {
    return TestingState(
      isEnabled: isEnabled ?? this.isEnabled,
      testEntitlement: testEntitlement ?? this.testEntitlement,
    );
  }
}

class TestingStateNotifier extends StateNotifier<TestingState> {
  TestingStateNotifier() : super(const TestingState());
  
  void setTestingMode(bool enabled, Entitlement entitlement) {
    if (kDebugMode) {
      state = TestingState(
        isEnabled: enabled,
        testEntitlement: entitlement,
      );
    }
  }
}

class RevenueCatNotifier extends StateNotifier<Entitlement> {
  final Ref _ref;
  
  RevenueCatNotifier(this._ref) : super(Entitlement.free) {
    init();
  }

  // Initialize RevenueCat and set up a listener for customer info updates
  Future<void> init() async {
    try {
      await updatePurchaseStatus();
      // Set up listener for purchase updates
      Purchases.addCustomerInfoUpdateListener((_) => updatePurchaseStatus());
    } catch (e) {
      debugPrint('Error initializing RevenueCat: $e');
    }
  }

  Future<void> updatePurchaseStatus() async {
    try {
      final testingState = _ref.read(testingStateProvider);
      if (testingState.isEnabled) {
        if (mounted) {
          state = testingState.testEntitlement;
        }
        return;
      }
      
      final entitlement = await PurchaseApi.getUserEntitlement();
      if (mounted) {
        state = entitlement;
      }
    } catch (e) {
      debugPrint('Error updating purchase status: $e');
      if (mounted) {
        state = Entitlement.free;
      }
    }
  }

  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
    await updatePurchaseStatus();
  }
  
  /// Set testing mode (only available in debug mode for simulators)
  void setTestingMode(bool enabled, Entitlement testEntitlement) {
    if (kDebugMode) {
      _ref.read(testingStateProvider.notifier).setTestingMode(enabled, testEntitlement);
      updatePurchaseStatus();
    }
  }
}
