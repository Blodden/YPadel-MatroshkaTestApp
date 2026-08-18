import AppTrackingTransparency
import AppMetricaCore
import Foundation

final class AnalyticsReporter {
    private var enabled = false

    init(apiKey: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            NSLog("YPoints: AppMetrica отключена — API key пуст")
            return
        }
        guard let configuration = AppMetricaConfiguration(apiKey: trimmedKey) else {
            NSLog("YPoints: AppMetrica не активирована — API key некорректен")
            return
        }
        guard
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            !appVersion.isEmpty,
            let appBuildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            let numericBuildNumber = UInt(appBuildNumber),
            numericBuildNumber > 0
        else {
            NSLog("YPoints: AppMetrica не активирована — версия или номер сборки некорректны")
            return
        }
        configuration.appVersion = appVersion
        configuration.appBuildNumber = appBuildNumber
        configuration.revenueAutoTrackingEnabled = false
        configuration.locationTracking = false
        configuration.accurateLocationTracking = false
        configuration.advertisingIdentifierTrackingEnabled =
            ATTrackingManager.trackingAuthorizationStatus == .authorized
        AppMetrica.activate(with: configuration)
        enabled = true
    }

    func report(_ name: String, parameters: [String: Any]? = nil) {
        guard enabled else { return }
        AppMetrica.reportEvent(name: name, parameters: parameters) { error in
            NSLog("YPoints: AppMetrica event \(name) error: \(error.localizedDescription)")
        }
    }

    func setAdvertisingIdentifierTracking(enabled: Bool) {
        guard self.enabled else { return }
        AppMetrica.isAdvertisingIdentifierTrackingEnabled = enabled
    }
}
