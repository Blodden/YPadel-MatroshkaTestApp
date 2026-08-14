import UIKit
import UserNotifications
import UserNotificationsUI

final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let titleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let detailLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.03, green: 0.25, blue: 0.17, alpha: 1)

        titleLabel.text = "YPadel"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)

        scoreLabel.text = "0 : 0"
        scoreLabel.textColor = UIColor(red: 0.68, green: 0.93, blue: 0.22, alpha: 1)
        scoreLabel.font = .monospacedDigitSystemFont(ofSize: 42, weight: .black)

        detailLabel.text = "Текущий матч"
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        detailLabel.font = .systemFont(ofSize: 13, weight: .medium)

        let stack = UIStackView(arrangedSubviews: [titleLabel, scoreLabel, detailLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        titleLabel.text = content.title.isEmpty ? "YPadel" : content.title
        detailLabel.text = content.body
        scoreLabel.text = content.userInfo["score"] as? String ?? "0 : 0"
    }
}
