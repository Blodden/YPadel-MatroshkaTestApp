import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var featureFlagTask: URLSessionDataTask?
    private var minimumDisplayTimeElapsed = false
    private var featureFlagRequestFinished = false
    private var startupFinished = false
    private var pendingMatchDeepLink = false

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

        pendingMatchDeepLink = connectionOptions.urlContexts.contains {
            $0.url.scheme == "ypoints"
        }

        let startupViewController = StartupViewController()
        startupViewController.onFirstAppearance = { [weak self] in
            self?.beginStartup(using: services)
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = startupViewController
        window.makeKeyAndVisible()
        self.window = window
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard URLContexts.contains(where: { $0.url.scheme == "ypoints" }) else { return }
        guard let navigationController = window?.rootViewController as? UINavigationController else {
            pendingMatchDeepLink = true
            return
        }
        let mainViewController = navigationController.viewControllers.first as? MainViewController
        mainViewController?.showMatchFromDeepLink()
    }

    private func beginStartup(using services: AppServices) {
        guard !startupFinished, featureFlagTask == nil else { return }

        featureFlagTask = services.apiClient.fetchFeatureFlags(
            appId: services.configuration.appIdentifier,
            appVersion: services.configuration.appVersion
        ) { [weak self] result in
            guard let self else { return }
            self.featureFlagTask = nil
            var appliedRemoteValue = false
            if case let .success(response) = result {
                appliedRemoteValue = services.featureFlags.apply(response)
            }
            if appliedRemoteValue {
                reloadMatchWidgets()
            }
            if self.startupFinished {
                if appliedRemoteValue {
                    self.refreshMainFeatureFlagStatus()
                }
                return
            }
            self.featureFlagRequestFinished = true
            if self.minimumDisplayTimeElapsed {
                self.finishStartup(using: services)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self, !self.startupFinished else { return }
            self.minimumDisplayTimeElapsed = true
            if self.featureFlagRequestFinished {
                self.finishStartup(using: services)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self, !self.startupFinished else { return }
            self.finishStartup(using: services)
        }
    }

    private func refreshMainFeatureFlagStatus() {
        guard let navigationController = window?.rootViewController as? UINavigationController else {
            return
        }
        let mainViewController = navigationController.viewControllers.first as? MainViewController
        mainViewController?.refreshFeatureFlagStatus()
    }

    private func finishStartup(using services: AppServices) {
        guard !startupFinished else { return }
        startupFinished = true

        let mainViewController = MainViewController(
            configuration: services.configuration,
            apiClient: services.apiClient,
            analytics: services.analytics,
            featureFlags: services.featureFlags,
            installationId: services.installationId
        )
        let navigationController = UINavigationController(rootViewController: mainViewController)
        window?.rootViewController = navigationController

        if pendingMatchDeepLink {
            pendingMatchDeepLink = false
            mainViewController.showMatchFromDeepLink()
        }
    }
}

private final class StartupViewController: UIViewController {
    var onFirstAppearance: (() -> Void)?
    private var didNotifyAppearance = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "LaunchBackground")
            ?? UIColor(red: 0.03, green: 0.25, blue: 0.17, alpha: 1)

        let imageView = UIImageView(image: UIImage(named: "LaunchIcon"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "YPoints запускается"
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 160),
            imageView.heightAnchor.constraint(equalToConstant: 160)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didNotifyAppearance else { return }
        didNotifyAppearance = true
        onFirstAppearance?()
        onFirstAppearance = nil
    }
}
