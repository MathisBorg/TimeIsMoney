//
//  UnlockView.swift
//  TimeIsMoney
//

import SwiftUI

struct UnlockView: View {
    let appName: String
    let onUnlock: (UnlockOption) -> Bool
    let onDismiss: () -> Void

    @StateObject private var wallet = WalletManager.shared
    @StateObject private var settings = InvestmentSettings.shared
    @State private var selectedOption: UnlockOption?
    @State private var showInsufficientFunds = false
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                Text("Time Limit Reached")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You've reached your daily limit for \(appName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            // Balance
            HStack {
                Text("Available Balance:")
                    .foregroundStyle(.secondary)
                Text(String(format: "$%.2f", wallet.balance))
                    .fontWeight(.bold)
            }
            .font(.subheadline)

            // Unlock Options
            VStack(spacing: 12) {
                Text("Unlock for more time")
                    .font(.headline)

                ForEach(wallet.unlockOptions) { option in
                    UnlockOptionRow(
                        option: option,
                        isSelected: selectedOption?.id == option.id,
                        isAffordable: wallet.balance >= option.price,
                        action: { selectedOption = option }
                    )
                }
            }
            .padding(.horizontal)

            // Investment Preview
            if let option = selectedOption {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your \(option.priceText) will be invested in:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        ForEach(settings.allocations) { allocation in
                            let amount = option.price * (allocation.percentage / 100.0)
                            if amount > 0 {
                                VStack(spacing: 2) {
                                    Circle()
                                        .fill(allocation.color)
                                        .frame(width: 8, height: 8)
                                    Text(String(format: "$%.2f", amount))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                    Text(allocation.name)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            Spacer()

            // Insufficient Funds Warning
            if showInsufficientFunds {
                Text("Insufficient funds. Please add more credit.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Buttons
            VStack(spacing: 12) {
                Button(action: unlock) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(selectedOption != nil ? "Pay & Unlock" : "Select an option")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedOption != nil ? .blue : .gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedOption == nil || isProcessing)

                Button("Stay Focused") {
                    onDismiss()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
    }

    private func unlock() {
        guard let option = selectedOption else { return }

        if wallet.balance < option.price {
            showInsufficientFunds = true
            return
        }

        isProcessing = true
        showInsufficientFunds = false

        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = onUnlock(option)
            isProcessing = false

            if !success {
                showInsufficientFunds = true
            }
        }
    }
}

struct UnlockOptionRow: View {
    let option: UnlockOption
    let isSelected: Bool
    let isAffordable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.durationText)
                        .font(.headline)
                        .foregroundStyle(isAffordable ? .primary : .secondary)
                    if !isAffordable {
                        Text("Insufficient funds")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Spacer()

                Text(option.priceText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isAffordable ? .blue : .secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
        }
        .disabled(!isAffordable)
    }
}

// MARK: - Preview

#Preview {
    UnlockView(
        appName: "Instagram",
        onUnlock: { option in
            print("Unlocking for \(option.durationText)")
            return true
        },
        onDismiss: {
            print("Dismissed")
        }
    )
}
