import 'package:flutter_test/flutter_test.dart';
import 'package:scalemasterguitar/utils/audio_utils.dart';

void main() {
  group('AudioPlayerManager Tests', () {
    late AudioPlayerManager audioPlayerManager;

    setUp(() {
      audioPlayerManager = AudioPlayerManager();
    });

    test('AudioPlayerManager is a singleton', () {
      final instance1 = AudioPlayerManager();
      final instance2 = AudioPlayerManager();
      expect(instance1, same(instance2));
    });

    test('Initial volume is 1.0', () {
      expect(audioPlayerManager.currentVolume, 1.0);
    });

    test('Volume can be changed', () async {
      await audioPlayerManager.setVolume(0.5);
      expect(audioPlayerManager.currentVolume, 0.5);
    });

    test('Volume stream emits new values', () async {
      final volumeValues = <double>[];
      final subscription = audioPlayerManager.volumeStream.listen(volumeValues.add);
      
      await audioPlayerManager.setVolume(0.3);
      await audioPlayerManager.setVolume(0.6);
      
      // Allow time for the stream to emit values
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(volumeValues, equals([1.0, 0.3, 0.6]));
      await subscription.cancel();
    });

    test('playSound handles errors gracefully', () async {
      // Test with non-existent asset to trigger error handling
      await audioPlayerManager.playSound('non_existent_asset.mp3');
      // If we get here without throwing, error handling is working
    });

    test('stop method works', () async {
      // This is a basic test that just verifies the method can be called
      await audioPlayerManager.stop();
      // If we get here without throwing, the test passes
    });
  });
}
