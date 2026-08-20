import UIKit
import UserNotifications
import UserNotificationsUI

final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let titleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let detailLabel = UILabel()
#if IMPORTED_NOTIFICATIONS_AVAILABLE
    private lazy var importedRenderer: ImportedNotificationContentRendering = ImportedNotificationRenderer()
#endif

    override func viewDidLoad() {
        super.viewDidLoad()
#if IMPORTED_NOTIFICATIONS_AVAILABLE
        if SharedFeatureFlags.cloudSyncEnabled(bundle: .main) {
            importedRenderer.install(in: self)
            return
        }
#endif
        configureYPointsContent()
    }

    func didReceive(_ notification: UNNotification) {
#if IMPORTED_NOTIFICATIONS_AVAILABLE
        if SharedFeatureFlags.cloudSyncEnabled(bundle: .main) {
            importedRenderer.didReceive(notification)
            return
        }
#endif
        let content = notification.request.content
        titleLabel.text = content.title.isEmpty ? "YPoints" : content.title
        detailLabel.text = content.body
        let rawScore = content.userInfo["score"] as? String ?? "0:0"
        let games = content.userInfo["games"] as? String ?? "0 : 0"
        let sets = content.userInfo["sets"] as? String ?? "0 : 0"
        scoreLabel.text = rawScore.replacingOccurrences(of: ":", with: " : ")
        scoreLabel.accessibilityValue = rawScore.replacingOccurrences(of: ":", with: " — ")
        detailLabel.text = L10n.format("notification.detailsFormat", content.body, games, sets)
    }

    private func configureYPointsContent() {
        view.backgroundColor = UIColor(red: 0.03, green: 0.25, blue: 0.17, alpha: 1)

        titleLabel.text = "YPoints"
        titleLabel.textColor = .white
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        scoreLabel.text = "0 : 0"
        scoreLabel.textColor = UIColor(red: 0.68, green: 0.93, blue: 0.22, alpha: 1)
        scoreLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
            for: .monospacedDigitSystemFont(ofSize: 42, weight: .black)
        )
        scoreLabel.adjustsFontForContentSizeCategory = true
        scoreLabel.accessibilityLabel = L10n.text("score.accessibility")

        detailLabel.text = L10n.text("notification.updatedPlain")
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        detailLabel.font = .preferredFont(forTextStyle: .footnote)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.numberOfLines = 2
        detailLabel.textAlignment = .center

        let openButton = makeButton(title: L10n.text("notification.open"), action: #selector(openMatch))
        let hideButton = makeButton(title: L10n.text("notification.hide"), action: #selector(hideNotification))
        let actions = UIStackView(arrangedSubviews: [openButton, hideButton])
        actions.axis = .horizontal
        actions.distribution = .fillEqually
        actions.spacing = 8

        let stack = UIStackView(arrangedSubviews: [titleLabel, scoreLabel, detailLabel, actions])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 12),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12),
            openButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            hideButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.gray()
        configuration.title = title
        configuration.cornerStyle = .medium
        configuration.baseForegroundColor = .white
        configuration.background.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func openMatch() {
        extensionContext?.performNotificationDefaultAction()
    }

    @objc private func hideNotification() {
        extensionContext?.dismissNotificationContentExtension()
    }
}
