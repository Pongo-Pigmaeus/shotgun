import SwiftUI
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}

@main
struct ShotgunApp: App {
    @StateObject private var store = AppStore()
    @AppStorage("appearancePreference") private var appearancePreference = AppearancePreference.system.rawValue
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(AppearancePreference(rawValue: appearancePreference)?.colorScheme)
                .task {
                    await store.refreshNotificationPermission()
                }
        }
    }
}
