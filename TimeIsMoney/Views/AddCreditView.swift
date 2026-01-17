//
//  AddCreditView.swift
//  TimeIsMoney
//

import SwiftUI

struct AddCreditView: View {
    @ObservedObject var wallet: WalletManager
    @Binding var isPresented: Bool

    let creditOptions: [Double] = [5, 10, 20, 50, 100]
    @State private var selectedAmount: Double = 20
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                }

                // Title
                VStack(spacing: 8) {
                    Text("Add Credit")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("You need at least $1.00 to use TimeIsMoney. This credit will be invested when you exceed your screen time limits.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Current Balance
                if wallet.balance > 0 {
                    HStack {
                        Text("Current balance:")
                            .foregroundStyle(.secondary)
                        Text(String(format: "$%.2f", wallet.balance))
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }

                // Amount Selection
                VStack(spacing: 16) {
                    Text("Select amount")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(creditOptions, id: \.self) { amount in
                            CreditOptionButton(
                                amount: amount,
                                isSelected: selectedAmount == amount,
                                action: { selectedAmount = amount }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Add Credit Button
                Button(action: addCredit) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Add \(String(format: "$%.0f", selectedAmount))")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isProcessing)
                .padding(.horizontal, 24)

                // Skip for now (if they have some balance)
                if wallet.balance > 0 {
                    Button("Skip for now") {
                        isPresented = false
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer().frame(height: 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if wallet.balance >= 1.0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }

    private func addCredit() {
        isProcessing = true

        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            wallet.deposit(amount: selectedAmount)
            isProcessing = false

            // Auto-dismiss if balance is now sufficient
            if wallet.balance >= 1.0 {
                isPresented = false
            }
        }
    }
}

struct CreditOptionButton: View {
    let amount: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(format: "$%.0f", amount))
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? .blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? .blue : .clear, lineWidth: 2)
                )
        }
    }
}

#Preview {
    AddCreditView(wallet: WalletManager.shared, isPresented: .constant(true))
}
