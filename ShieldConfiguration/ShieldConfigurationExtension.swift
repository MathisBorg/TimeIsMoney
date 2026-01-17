//
//  ShieldConfigurationExtension.swift
//  ShieldConfiguration
//
//  Created by TimeIsMoney
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Extension qui personnalise l'ecran de blocage
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private let appGroupID = "group.com.mathisligout.timeismoney"
    private let balanceKey = "walletBalance"

    // MARK: - Application Shield

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return createShieldConfiguration(title: "Temps ecoule")
    }

    // MARK: - Application Category Shield

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return createShieldConfiguration(title: "Temps ecoule")
    }

    // MARK: - Web Domain Shield

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return createShieldConfiguration(title: "Site bloque")
    }

    // MARK: - Web Domain in Category Shield

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return createShieldConfiguration(title: "Site bloque")
    }

    // MARK: - Helper

    private func createShieldConfiguration(title: String) -> ShieldConfiguration {
        // Lire le solde actuel depuis App Group
        let balance = UserDefaults(suiteName: appGroupID)?.double(forKey: balanceKey) ?? 0.0
        let balanceText = String(format: "%.2f", balance)

        // Message simple avec solde
        let subtitle = "Solde: \(balanceText)$\n\nCliquez sur Debloquer pour ajouter du temps"

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.black,
            icon: UIImage(systemName: "clock.badge.exclamationmark.fill"),
            title: ShieldConfiguration.Label(
                text: title,
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor.lightGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Debloquer",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor.systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Fermer",
                color: UIColor.lightGray
            )
        )
    }
}
