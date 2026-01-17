//
//  LimitsManager.swift
//  TimeIsMoney
//
//  Created by TimeIsMoney
//

import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import Combine

@MainActor
class LimitsManager: ObservableObject {

    // MARK: - Published Properties

    @Published var limits: [AppLimit] = []
    @Published var currentSelection = FamilyActivitySelection()
    @Published var isShowingAppPicker: Bool = false

    // MARK: - Private Properties

    private let store = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()

    // App Group pour partager les données avec les extensions
    private let appGroupID = "group.com.mathisligout.timeismoney"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    private let limitsKey = "savedLimits"

    // MARK: - Initialization

    init() {
        loadSavedLimits()
        setupNotifications()
    }

    private func setupNotifications() {
        Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .reapplyShields) {
                self?.reapplyAllShields()
            }
        }
    }

    func reapplyAllShields() {
        for limit in limits where limit.isActive {
            applyShield(for: limit)
        }
    }

    // MARK: - Limit Management

    /// Ajoute une nouvelle limite
    func addLimit(selection: FamilyActivitySelection, minutes: Int) {
        let newLimit = AppLimit(selection: selection, timeLimitMinutes: minutes)
        limits.append(newLimit)

        // Sauvegarder
        saveLimits()

        // Appliquer le shield immediatement (avec le store nomme)
        applyShield(for: newLimit)

        // Programmer le monitoring pour les futures sessions
        scheduleMonitoring(for: newLimit)
    }

    /// Supprime une limite
    func removeLimit(_ limit: AppLimit) {
        // Arrêter le monitoring
        stopMonitoring(for: limit)

        // Retirer le shield
        removeShield(for: limit)

        // Retirer de la liste
        limits.removeAll { $0.id == limit.id }

        // Sauvegarder
        saveLimits()
    }

    /// Active ou desactive une limite
    func toggleLimit(_ limit: AppLimit) {
        guard let index = limits.firstIndex(where: { $0.id == limit.id }) else { return }

        limits[index].isActive.toggle()

        if limits[index].isActive {
            // Reactiver : appliquer le shield et relancer le monitoring
            applyShield(for: limits[index])
            scheduleMonitoring(for: limits[index])
        } else {
            // Desactiver : arreter le monitoring et retirer le shield
            removeShield(for: limits[index])
            stopMonitoring(for: limits[index])
        }

        saveLimits()
    }

    // MARK: - Shield Management

    /// Applique un shield avec le store PAR DEFAUT (pour que ShieldActionDelegate fonctionne)
    private func applyShield(for limit: AppLimit) {
        // IMPORTANT: Utiliser le store par défaut (non-nommé) pour que ShieldActionDelegate soit invoqué
        // Les stores nommés semblent ne pas déclencher correctement ShieldActionDelegate

        // Sauvegarder l'ID de la limite active pour référence
        sharedDefaults?.set(limit.id.uuidString, forKey: "activeShieldStoreName")
        sharedDefaults?.synchronize()

        // Appliquer aux applications via le store par défaut
        store.shield.applications = limit.selection.applicationTokens

        // Appliquer aux categories
        store.shield.applicationCategories = .specific(limit.selection.categoryTokens)

        // Appliquer aux sites web
        store.shield.webDomains = limit.selection.webDomainTokens
    }

    /// Retire le shield d'une limite
    private func removeShield(for limit: AppLimit) {
        // Nettoyer le store par défaut
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    /// Retire tous les shields
    func clearAllShields() {
        // Nettoyer le store par défaut
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.clearAllSettings()
    }

    // MARK: - Device Activity Monitoring

    /// Programme le monitoring pour une limite
    private func scheduleMonitoring(for limit: AppLimit) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let activityName = DeviceActivityName(limit.id.uuidString)

        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            .init(limit.id.uuidString): DeviceActivityEvent(
                applications: limit.selection.applicationTokens,
                categories: limit.selection.categoryTokens,
                webDomains: limit.selection.webDomainTokens,
                threshold: DateComponents(minute: limit.timeLimitMinutes)
            )
        ]

        do {
            try deviceActivityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: events
            )
        } catch {
            print("Error starting monitoring: \(error)")
        }
    }

    /// Arrête le monitoring pour une limite
    private func stopMonitoring(for limit: AppLimit) {
        let activityName = DeviceActivityName(limit.id.uuidString)
        deviceActivityCenter.stopMonitoring([activityName])
    }

    // MARK: - Persistence (Shared via App Group)

    /// Sauvegarde les limites
    private func saveLimits() {
        if let encoded = try? JSONEncoder().encode(limits) {
            // Sauvegarder dans App Group (pour les extensions)
            sharedDefaults?.set(encoded, forKey: limitsKey)
            sharedDefaults?.synchronize()

            // Sauvegarder aussi localement
            UserDefaults.standard.set(encoded, forKey: limitsKey)
        }
    }

    /// Charge les limites
    private func loadSavedLimits() {
        // Essayer d'abord App Group, sinon local
        let data = sharedDefaults?.data(forKey: limitsKey) ?? UserDefaults.standard.data(forKey: limitsKey)

        guard let data = data,
              let decoded = try? JSONDecoder().decode([AppLimit].self, from: data) else {
            return
        }

        limits = decoded

        // Reappliquer les shields et relancer le monitoring pour les limites actives
        for limit in limits where limit.isActive {
            applyShield(for: limit)
            scheduleMonitoring(for: limit)
        }
    }
}
