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

/// Extension qui surveille l'activité et déclenche les blocages
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // App Group pour lire les limites sauvegardées
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
        // Nettoyer les shields à la fin de la journée
        // IMPORTANT: Utiliser le store par défaut pour que ShieldActionDelegate soit invoqué
        let store = ManagedSettingsStore()
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    // MARK: - Event Callbacks

    /// Appelé quand un événement (limite atteinte) se déclenche
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Charger la limite correspondante depuis App Group
        guard let limit = loadLimit(withId: activity.rawValue) else {
            return
        }

        // Sauvegarder le nom du store actif pour que ShieldAction puisse le retirer
        sharedDefaults?.set(activity.rawValue, forKey: "activeShieldStoreName")
        sharedDefaults?.synchronize()

        // IMPORTANT: Utiliser le store par défaut (non-nommé) pour que ShieldActionDelegate soit invoqué
        // Les stores nommés ne déclenchent pas correctement ShieldActionDelegate
        let store = ManagedSettingsStore()
        store.shield.applications = limit.selection.applicationTokens
        store.shield.applicationCategories = .specific(limit.selection.categoryTokens)
        store.shield.webDomains = limit.selection.webDomainTokens
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
