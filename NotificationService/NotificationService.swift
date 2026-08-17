import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        let mutableContent = request.content.mutableCopy() as? UNMutableNotificationContent
        bestAttemptContent = mutableContent

        guard let mutableContent else {
            contentHandler(request.content)
            return
        }

        if let score = request.content.userInfo["score"] as? String {
            mutableContent.title = "YPoints"
            let games = request.content.userInfo["games"] as? String ?? "0 : 0"
            let sets = request.content.userInfo["sets"] as? String ?? "0 : 0"
            mutableContent.subtitle = "Очки \(score) • Геймы \(games) • Сеты \(sets)"
        }
        if mutableContent.body.isEmpty {
            mutableContent.body = "Состояние матча обновилось."
        }
        mutableContent.categoryIdentifier = "YPOINTS_MATCH"
        finish(with: mutableContent)
    }

    override func serviceExtensionTimeWillExpire() {
        guard let bestAttemptContent else { return }
        finish(with: bestAttemptContent)
    }

    private func finish(with content: UNNotificationContent) {
        guard let contentHandler else { return }
        self.contentHandler = nil
        contentHandler(content)
    }
}
