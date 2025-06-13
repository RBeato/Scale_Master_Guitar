import 'package:async/async.dart'; // Import async package

class Debouncer {
// Wrap your button's onPressed handler with a debounced function
  static void handleButtonPress(Function onTap) {
    final AsyncMemoizer memoizer =
        AsyncMemoizer(); // Create a new AsyncMemoizer instance

    memoizer.runOnce(() async {
      onTap();
      // This function will only be executed once, even if called multiple times rapidly
      await Future.delayed(
          const Duration(milliseconds: 100)); // Reduced for musical responsiveness
    });
  }
}
