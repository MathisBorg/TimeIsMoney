//
//  TimeIsMoneyApp.swift
//  TimeIsMoney
//

import SwiftUI
import UserNotifications

// MARK: - Main App

@main
struct TimeIsMoneyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var limitsManager = LimitsManager()
    @State private var showQuickUnlock = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(walletManager)
                .environmentObject(limitsManager)
                .fullScreenCover(isPresented: $showQuickUnlock) {
                    QuickUnlockView()
                        .environmentObject(walletManager)
                        .environmentObject(limitsManager)
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .showQuickUnlock)) { _ in
                    showQuickUnlock = true
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // URL format: timeismoney://unlock
        guard url.scheme == "timeismoney" else { return }

        if url.host == "unlock" {
            showQuickUnlock = true
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let showQuickUnlock = Notification.Name("showQuickUnlock")
}

// MARK: - App Delegate pour gerer les notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configurer le delegate des notifications
        UNUserNotificationCenter.current().delegate = self

        // Demander l'autorisation pour les notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Erreur autorisation notifications: \(error)")
            }
        }

        return true
    }

    // Appele quand l'utilisateur tape sur une notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // Verifier si c'est un deep link pour debloquer
        if let deepLink = userInfo["deepLink"] as? String, deepLink == "timeismoney://unlock" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .showQuickUnlock, object: nil)
            }
        }

        completionHandler()
    }

    // Appele quand une notification arrive pendant que l'app est au premier plan
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Afficher la notification meme si l'app est au premier plan
        completionHandler([.banner, .sound])
    }
}
