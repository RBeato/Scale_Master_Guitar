import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure audio session for background playback and mixing with other audio
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .default,
        options: [.mixWithOthers, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
      )
      try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
      
      // Enable audio in silent mode
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Failed to set audio session category. Error: \(error)")
    }
    
    // Register for audio session interruptions
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption(notification:)),
      name: AVAudioSession.interruptionNotification,
      object: nil
    )
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  @objc func handleInterruption(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }
    
    switch type {
    case .began:
      // Audio was interrupted, pause playback
      break
    case .ended:
      // Try to resume playback if appropriate
      if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if options.contains(.shouldResume) {
          do {
            try AVAudioSession.sharedInstance().setActive(true)
          } catch {
            print("Failed to reactivate audio session: \(error)")
          }
        }
      }
    @unknown default:
      break
    }
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Clean up audio session
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      print("Failed to deactivate audio session: \(error)")
    }
  }
}
