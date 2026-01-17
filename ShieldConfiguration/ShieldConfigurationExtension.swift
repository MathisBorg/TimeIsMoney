//
//  ShieldConfigurationExtension.swift
//  ShieldConfiguration
//
//  Created by TimeIsMoney
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Extension qui personnalise l'écran de blocage
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private let appGroupID = "group.com.mathisligout.timeismoney"
    private let balanceKey = "walletBalance"
    private let unlockPrice: Double = 0.50

    // MARK: - Application Shield

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return createShieldConfiguration(title: "Time Limit Reached")
    }

    // MARK: - Application Category Shield

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return createShieldConfiguration(title: "Time Limit Reached")
    }

    // MARK: - Web Domain Shield

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return createShieldConfiguration(title: "Site Blocked")
    }

    // MARK: - Web Domain in Category Shield

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return createShieldConfiguration(title: "Site Blocked")
    }

    // MARK: - Helper

    private func createShieldConfiguration(title: String) -> ShieldConfiguration {
        // Lire le solde actuel depuis App Group
        let balance = UserDefaults(suiteName: appGroupID)?.double(forKey: balanceKey) ?? 0.0
        let balanceText = String(format: "$%.2f", balance)

        // Créer le subtitle avec le solde et info si insuffisant
        let subtitle: String
        if balance >= unlockPrice {
            subtitle = "Balance: \(balanceText)\nPay to unlock for 15 minutes.\nYour $0.50 will be invested!"
        } else {
            subtitle = "Balance: \(balanceText) (insuffisant)\nAjoutez du crédit dans l'app TimeIsMoney"
        }

        // Texte du bouton primaire selon le solde
        let primaryButtonText = balance >= unlockPrice
            ? "Unlock - $0.50"
            : "Unlock - $0.50 (solde: \(balanceText))"

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.black,
            icon: UIImage(systemName: "dollarsign.circle.fill"),
            title: ShieldConfiguration.Label(
                text: title,
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor.lightGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: primaryButtonText,
                color: .black
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.2, green: 0.9, blue: 0.7, alpha: 1.0),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close App",
                color: UIColor.lightGray
            )
        )
    }
}
