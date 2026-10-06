import AVFoundation
import AppIntents
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var ringtones: RingtoneChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "RingtoneChannel") {
      ringtones = RingtoneChannel(registrar: registrar)
    }
    if let registrar = registrar(forPlugin: "BackTapChannel") {
      BackTapChannel.shared.attach(messenger: registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class RingtoneChannel {
  private let registrar: FlutterPluginRegistrar
  private let channel: FlutterMethodChannel
  private var player: AVAudioPlayer?

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    channel = FlutterMethodChannel(name: "helpyy/ringtone", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "play":
      let args = call.arguments as? [String: Any]
      play(asset: args?["id"] as? String, loop: args?["loop"] as? Bool ?? true, result: result)
    case "stop":
      player?.stop()
      player = nil
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func play(asset: String?, loop: Bool, result: FlutterResult) {
    player?.stop()
    player = nil
    guard let asset,
      let path = Bundle.main.path(forResource: registrar.lookupKey(forAsset: asset), ofType: nil)
    else {
      result(FlutterError(code: "NOT_FOUND", message: "No bundled tone \(asset ?? "nil")", details: nil))
      return
    }
    do {
      let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
      player.numberOfLoops = loop ? -1 : 0
      player.play()
      self.player = player
      result(nil)
    } catch {
      result(FlutterError(code: "UNAVAILABLE", message: error.localizedDescription, details: nil))
    }
  }
}

class BackTapChannel {
  static let shared = BackTapChannel()

  private var channel: FlutterMethodChannel?
  private var isDartListening = false
  private var pending: Int?

  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "helpyy/back_tap", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "ready" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.isDartListening = true
      result(self?.pending)
      self?.pending = nil
    }
    self.channel = channel
  }

  func tapped(_ taps: Int) {
    guard isDartListening, let channel else {
      pending = taps
      return
    }
    channel.invokeMethod("tapped", arguments: taps) { [weak self] reply in
      if reply is FlutterError || (reply as? NSObject) === FlutterMethodNotImplemented {
        self?.isDartListening = false
        self?.pending = taps
      }
    }
  }
}

@available(iOS 16.0, *)
struct DoubleTapCallIntent: AppIntent {
  static let title: LocalizedStringResource = "Double tap escape call"
  static let description = IntentDescription("Rings your helpyy signal that uses a double tap.")
  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    BackTapChannel.shared.tapped(2)
    return .result()
  }
}

@available(iOS 16.0, *)
struct TripleTapCallIntent: AppIntent {
  static let title: LocalizedStringResource = "Triple tap escape call"
  static let description = IntentDescription("Rings your helpyy signal that uses a triple tap.")
  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    BackTapChannel.shared.tapped(3)
    return .result()
  }
}

@available(iOS 16.0, *)
struct HelpyyShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: DoubleTapCallIntent(),
      phrases: ["Double tap escape call in \(.applicationName)"],
      shortTitle: "Double tap call",
      systemImageName: "phone.fill"
    )
    AppShortcut(
      intent: TripleTapCallIntent(),
      phrases: ["Triple tap escape call in \(.applicationName)"],
      shortTitle: "Triple tap call",
      systemImageName: "phone.fill"
    )
  }
}
