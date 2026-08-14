import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let configuration = AppConfiguration(bundle: .main)
        let analytics = AnalyticsReporter(apiKey: configuration.appMetricaAPIKey)
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = 5
        let apiClient = APIClient(
            baseURL: configuration.apiBaseURL,
            session: URLSession(configuration: sessionConfiguration)
        )
        let mainViewController = MainViewController(
            configuration: configuration,
            apiClient: apiClient,
            analytics: analytics
        )
        let navigationController = UINavigationController(rootViewController: mainViewController)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
