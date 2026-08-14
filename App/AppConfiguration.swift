import Foundation

struct AppConfiguration {
    let appMetricaAPIKey: String
    let apiBaseURL: URL
    let appGroupIdentifier: String

    init(bundle: Bundle) {
        appMetricaAPIKey = bundle.object(forInfoDictionaryKey: "AppMetricaAPIKey") as? String ?? ""

        let rawURL = bundle.object(forInfoDictionaryKey: "APIBaseURL") as? String
        apiBaseURL = URL(string: rawURL ?? "") ?? URL(string: "http://localhost:8080")!

        appGroupIdentifier = bundle.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
            ?? "group.com.example.ypadel"
    }
}
