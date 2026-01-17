//
//  TimeIsMoneyApp.swift
//  TimeIsMoney
//

import SwiftUI
import UserNotifications

@main
struct TimeIsMoneyApp: App {

    init() {
        // Demander l'autorisation pour les notifications au lancement
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Erreur autorisation notifications: \(error)")
            } else if granted {
                print("Notifications autorisées")
            } else {
                print("Notifications refusées")
            }
        }
    }
}
