//
//  ShieldActionExtension.swift
//  ShieldAction
//
//  VERSION TEST 3 - Avec store par défaut pour retirer les shields
//

import ManagedSettings
import ManagedSettingsUI

/// Extension qui gère les actions des boutons sur l'écran de blocage
class ShieldActionExtension: ShieldActionDelegate {

    // Store par défaut - IMPORTANT: doit être le même que celui utilisé pour appliquer les shields
    private let store = ManagedSettingsStore()

    // MARK: - Application Actions

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    // MARK: - Category Actions

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    // MARK: - Web Domain Actions

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    // MARK: - Shared Handler

    private func handleAction(_ action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Bouton "Unlock" - retirer tous les shields et débloquer
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
            completionHandler(.defer)

        case .secondaryButtonPressed:
            // Bouton "Close App" - fermer l'app (shield reste actif)
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }
}
