#if IMPORTED_NOTIFICATIONS_AVAILABLE
import UserNotifications

protocol ImportedNotificationProcessing: AnyObject {
    func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    )

    func serviceExtensionTimeWillExpire()
}

// The imported source must provide:
// final class ImportedNotificationProcessor: ImportedNotificationProcessing
#endif
