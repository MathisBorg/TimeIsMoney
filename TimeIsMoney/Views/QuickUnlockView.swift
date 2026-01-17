//
//  QuickUnlockView.swift
//  TimeIsMoney
//
//  Vue rapide de deblocage quand on arrive depuis le Shield via Deep Link

import SwiftUI

struct QuickUnlockView: View {
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var limitsManager: LimitsManager
    @Environment(\.dismiss) var dismiss

    // Options de temps avec prix
    let unlockOptions: [(minutes: Int, price: Double)] = [
        (5, 0.25),
        (15, 0.50),
        (30, 1.00)
    ]

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)

                Text("Temps ecoule")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack {
                    Text("Solde disponible:")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f$", walletManager.balance))
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .font(.title3)
            }
            .padding(.top, 40)

            // Options de deblocage
            VStack(spacing: 16) {
                Text("Ajouter du temps")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ForEach(unlockOptions, id: \.minutes) { option in
                    QuickUnlockButton(
                        minutes: option.minutes,
                        price: option.price,
                        isAffordable: walletManager.balance >= option.price
                    ) {
                        unlockWithOption(minutes: option.minutes, price: option.price)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Bouton annuler
            Button(action: { dismiss() }) {
                Text("Annuler")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
    }

    private func unlockWithOption(minutes: Int, price: Double) {
        // 1. Utiliser la methode unlock existante de WalletManager
        let option = UnlockOption(duration: minutes, price: price)
        let success = walletManager.unlock(
            option: option,
            appName: "App",
            allocations: InvestmentSettings.shared.allocationsDictionary
        )

        guard success else { return }

        // 2. Retirer le shield
        limitsManager.clearAllShields()

        // 3. Retourner a l'app precedente
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Cette technique "suspend" l'app pour revenir a la precedente
            UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        }
    }
}

struct QuickUnlockButton: View {
    let minutes: Int
    let price: Double
    let isAffordable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("+\(minutes) minutes")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if !isAffordable {
                        Text("Solde insuffisant")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Spacer()

                Text(String(format: "%.2f€", price))
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(isAffordable ? Color.blue : Color.gray.opacity(0.3))
            .foregroundStyle(isAffordable ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isAffordable)
    }
}

#Preview {
    QuickUnlockView()
        .environmentObject(WalletManager.shared)
        .environmentObject(LimitsManager())
}
