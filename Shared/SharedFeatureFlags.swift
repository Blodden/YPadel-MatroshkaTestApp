import Foundation

struct SharedFeatureFlags {
    static func saveCloudSyncEnabled(
        _ enabled: Bool,
        appVersion: String,
        groupIdentifier: String
    ) {
        UserDefaults(suiteName: groupIdentifier)?.set(
            enabled,
            forKey: cloudSyncKey(appVersion: appVersion)
        )
    }

    static func cloudSyncEnabled(appVersion: String, groupIdentifier: String) -> Bool {
        let defaults = UserDefaults(suiteName: groupIdentifier)
        let key = cloudSyncKey(appVersion: appVersion)
        guard defaults?.object(forKey: key) != nil else { return true }
        return defaults?.bool(forKey: key) ?? true
    }

    static func cloudSyncEnabled(bundle: Bundle) -> Bool {
        guard
            let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let groupIdentifier = bundle.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
        else {
            return true
        }
        return cloudSyncEnabled(appVersion: appVersion, groupIdentifier: groupIdentifier)
    }

    private static func cloudSyncKey(appVersion: String) -> String {
        "feature.cloudSyncEnabled.\(appVersion)"
    }
}
