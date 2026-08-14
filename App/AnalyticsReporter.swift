import AppMetricaCore
import Foundation

final class AnalyticsReporter {
    private let enabled: Bool

    init(apiKey: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        enabled = !trimmedKey.isEmpty

        guard enabled, let configuration = AppMetricaConfiguration(apiKey: trimmedKey) else { return }
        AppMetrica.activate(with: configuration)
    }

    func report(_ name: String) {
        guard enabled else { return }
        AppMetrica.reportEvent(name: name, parameters: nil, onFailure: nil)
    }
}
