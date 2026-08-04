import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

  private func keyFromInfoPlist() -> String? {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String else {
      return nil
    }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if value.isEmpty || value.contains("$(") {
      return nil
    }
    return value
  }

  private func keyFromProcessEnv() -> String? {
    guard let value = ProcessInfo.processInfo.environment["GMS_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines),
          !value.isEmpty else {
      return nil
    }
    return value
  }

  private func keyFromBundledDotEnv() -> String? {
    let candidates = [
      Bundle.main.path(forResource: ".env", ofType: nil),
      Bundle.main.path(forResource: ".env", ofType: nil, inDirectory: "flutter_assets"),
      Bundle.main.path(forResource: ".env", ofType: nil, inDirectory: "Frameworks/App.framework/flutter_assets")
    ]

    for path in candidates.compactMap({ $0 }) {
      guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
        continue
      }
      for rawLine in content.components(separatedBy: .newlines) {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.isEmpty || line.hasPrefix("#") { continue }
        guard let idx = line.firstIndex(of: "=") else { continue }
        let key = String(line[..<idx]).trimmingCharacters(in: .whitespacesAndNewlines)
        if key != "MAPS_API_KEY" && key != "GMS_API_KEY" { continue }
        var value = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
          value = String(value.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if !value.isEmpty {
          return value
        }
      }
    }
    return nil
  }

  private func resolveMapsApiKey() -> String? {
    if let key = keyFromInfoPlist() { return key }
    if let key = keyFromProcessEnv() { return key }
    if let key = keyFromBundledDotEnv() { return key }
    return nil
  }
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = resolveMapsApiKey() {
      GMSServices.provideAPIKey(apiKey)
    } else {
      NSLog("[AidSense] Missing Google Maps API key. Set GMS_API_KEY build setting or MAPS_API_KEY in bundled .env")
    }

    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

