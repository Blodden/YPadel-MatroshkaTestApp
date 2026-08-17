import Foundation

struct AppConfiguration {
    let appMetricaAPIKey: String
    let apiBaseURL: URL
    let appGroupIdentifier: String
    let pushEnvironment: String
    let privacyPolicyURL: URL?
    let supportURL: URL?

    init(bundle: Bundle) {
        appMetricaAPIKey = bundle.object(forInfoDictionaryKey: "AppMetricaAPIKey") as? String ?? ""

        let rawURL = bundle.object(forInfoDictionaryKey: "APIBaseURL") as? String
        apiBaseURL = URL(string: rawURL ?? "") ?? URL(string: "http://localhost:8080")!

        appGroupIdentifier = bundle.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
            ?? "group.com.example.ypoints"
        pushEnvironment = bundle.object(forInfoDictionaryKey: "PushEnvironment") as? String ?? "sandbox"

        let privacyValue = bundle.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String ?? ""
        privacyPolicyURL = URL(string: privacyValue).flatMap { privacyValue.isEmpty ? nil : $0 }

        let supportValue = bundle.object(forInfoDictionaryKey: "SupportURL") as? String ?? ""
        supportURL = URL(string: supportValue).flatMap { supportValue.isEmpty ? nil : $0 }
    }
}
