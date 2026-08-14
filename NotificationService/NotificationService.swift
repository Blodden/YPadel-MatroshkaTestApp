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
            mutableContent.title = "YPadel • счет \(score)"
        }
        mutableContent.body = "\(mutableContent.body) Откройте карточку матча."
        mutableContent.categoryIdentifier = "YPADEL_MATCH"
        contentHandler(mutableContent)
    }

    override func serviceExtensionTimeWillExpire() {
        guard let contentHandler, let bestAttemptContent else { return }
        contentHandler(bestAttemptContent)
    }
}
