import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let services = appDelegate.services
        else { return }
        let mainViewController = MainViewController(
            configuration: services.configuration,
            apiClient: services.apiClient,
            analytics: services.analytics,
            installationId: services.installationId
        )
        let navigationController = UINavigationController(rootViewController: mainViewController)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard URLContexts.contains(where: { $0.url.scheme == "ypoints" }) else { return }
        let navigationController = window?.rootViewController as? UINavigationController
        let mainViewController = navigationController?.viewControllers.first as? MainViewController
        mainViewController?.showMatchFromDeepLink()
    }
}
