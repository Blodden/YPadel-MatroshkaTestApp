import AppTrackingTransparency
import AppMetricaCore
import Foundation

final class AnalyticsReporter {
    private let primaryAPIKey: String
    private var customReporter: AppMetricaReporting?

    init(apiKey: String) {
        primaryAPIKey = apiKey
        let configuration = AppMetricaConfiguration(apiKey: apiKey)!
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let appBuildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        configuration.appVersion = appVersion
        configuration.appBuildNumber = appBuildNumber
        configuration.revenueAutoTrackingEnabled = false
        configuration.locationTracking = false
        configuration.accurateLocationTracking = false
        configuration.advertisingIdentifierTrackingEnabled =
            ATTrackingManager.trackingAuthorizationStatus == .authorized
        AppMetrica.activate(with: configuration)
    }

    func report(_ name: String, parameters: [String: Any]? = nil) {
        if let customReporter {
            customReporter.reportEvent(name: name, parameters: parameters, onFailure: nil)
            return
        }
        AppMetrica.reportEvent(name: name, parameters: parameters, onFailure: nil)
    }

    func changeAPIKey(_ apiKey: String) {
        if apiKey == primaryAPIKey {
            customReporter?.pauseSession()
            customReporter = nil
            return
        }

        let reporter = AppMetrica.reporter(for: apiKey)!
        customReporter?.pauseSession()
        reporter.resumeSession()
        customReporter = reporter
    }

    func setAdvertisingIdentifierTracking(enabled: Bool) {
        AppMetrica.isAdvertisingIdentifierTrackingEnabled = enabled
    }
}
