//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//
//  Created by TimeIsMoney
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation
import UserNotifications

/// Extension qui surveille l'activite et declenche les blocages
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // App Group pour lire les limites sauvegardees
    private let appGroupID = "group.com.mathisligout.timeismoney"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    private let limitsKey = "savedLimits"

    // MARK: - Interval Callbacks

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Nettoyer les shields a la fin de la journee
        // IMPORTANT: Utiliser le store par defaut pour que ShieldActionDelegate soit invoque
        let store = ManagedSettingsStore()
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    // MARK: - Event Callbacks

    /// Appele quand un evenement (limite atteinte) se declenche
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Charger la limite correspondante depuis App Group
        guard let limit = loadLimit(withId: activity.rawValue) else {
            return
        }

        // Sauvegarder le nom du store actif pour que ShieldAction puisse le retirer
        sharedDefaults?.set(activity.rawValue, forKey: "activeShieldStoreName")
        sharedDefaults?.synchronize()

        // IMPORTANT: Utiliser le store par defaut (non-nomme) pour que ShieldActionDelegate soit invoque
        // Les stores nommes ne declenchent pas correctement ShieldActionDelegate
        let store = ManagedSettingsStore()
        store.shield.applications = limit.selection.applicationTokens
        store.shield.applicationCategories = .specific(limit.selection.categoryTokens)
        store.shield.webDomains = limit.selection.webDomainTokens

        // Envoyer une notification locale pour permettre le deblocage
        sendUnlockNotification()
    }

    // MARK: - Notification

    private func sendUnlockNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Temps ecoule"
        content.body = "Appuyez pour ajouter du temps"
        content.sound = .default
        // Deep link vers l'app pour debloquer
        content.userInfo = ["deepLink": "timeismoney://unlock"]

        let request = UNNotificationRequest(
            identifier: "unlock-\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur notification: \(error)")
            }
        }
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    // MARK: - Helper Methods

    private func loadLimit(withId id: String) -> AppLimit? {
        guard let data = sharedDefaults?.data(forKey: limitsKey),
              let limits = try? JSONDecoder().decode([AppLimit].self, from: data) else {
            return nil
        }
        return limits.first { $0.id.uuidString == id }
    }
}

// MARK: - AppLimit Model (doit correspondre exactement à l'app principale)

struct AppLimit: Codable, Identifiable {
    let id: UUID
    var selection: FamilyActivitySelection
    var timeLimitMinutes: Int
    var isActive: Bool
    var createdAt: Date

    var formattedTimeLimit: String {
        let hours = timeLimitMinutes / 60
        let minutes = timeLimitMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes) min"
        }
    }
}
