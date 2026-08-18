import UIKit
import UserNotifications

final class AppServices {
    let configuration: AppConfiguration
    let apiClient: APIClient
    let analytics: AnalyticsReporter
    let featureFlags: FeatureFlagStore
    let installationId: String

    init(bundle: Bundle) {
        configuration = AppConfiguration(bundle: bundle)

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = 7
        sessionConfiguration.timeoutIntervalForResource = 12
        apiClient = APIClient(
            baseURL: configuration.apiBaseURL,
            session: URLSession(configuration: sessionConfiguration)
        )
        let defaults = UserDefaults.standard
        analytics = AnalyticsReporter(apiKey: configuration.appMetricaAPIKey)
        featureFlags = FeatureFlagStore(defaults: defaults)
        if let storedId = defaults.string(forKey: "installation.id") {
            installationId = storedId
        } else {
            let newId = UUID().uuidString
            defaults.set(newId, forKey: "installation.id")
            installationId = newId
        }
    }

    func syncPushToken(_ token: String) {
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "push.deviceToken")
        guard featureFlags.cloudSyncEnabled else { return }
        let snapshot = MatchSnapshot.load(groupIdentifier: configuration.appGroupIdentifier)
        let request = SyncRequest(
            appId: configuration.appIdentifier,
            installationId: installationId,
            matchToken: defaults.string(forKey: "match.token"),
            clientRevision: snapshot.revision,
            snapshot: snapshot,
            push: PushRegistration(
                token: token,
                environment: configuration.pushEnvironment,
                enabled: true
            )
        )
        apiClient.sync(request) { result in
            guard case let .success(response) = result else { return }
            defaults.set(response.matchToken, forKey: "match.token")
        }
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private(set) var services: AppServices?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        services = AppServices(bundle: .main)

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        let openAction = UNNotificationAction(identifier: "OPEN_MATCH", title: "Открыть")
        let hideAction = UNNotificationAction(
            identifier: "HIDE_MATCH",
            title: "Скрыть",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: "YPOINTS_MATCH",
            actions: [openAction, hideAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        notificationCenter.setNotificationCategories([category])
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        services?.syncPushToken(token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NSLog("YPoints: APNs registration failed: \(error.localizedDescription)")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
