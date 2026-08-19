#if IMPORTED_NOTIFICATIONS_AVAILABLE
import UIKit
import UserNotifications

protocol ImportedNotificationContentRendering: AnyObject {
    func install(in viewController: UIViewController)
    func didReceive(_ notification: UNNotification)
}

// The imported source must provide:
// final class ImportedNotificationRenderer: ImportedNotificationContentRendering
#endif
