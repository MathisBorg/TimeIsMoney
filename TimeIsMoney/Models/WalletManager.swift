//
//  WalletManager.swift
//  TimeIsMoney
//

import Foundation
import SwiftUI

// MARK: - Transaction Model

struct Transaction: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: TransactionType
    let amount: Double
    let description: String
    let allocations: [String: Double]?

    init(id: UUID = UUID(), date: Date = Date(), type: TransactionType, amount: Double, description: String, allocations: [String: Double]? = nil) {
        self.id = id
        self.date = date
        self.type = type
        self.amount = amount
        self.description = description
        self.allocations = allocations
    }
}

enum TransactionType: String, Codable {
    case deposit = "deposit"
    case unlock = "unlock"
}

// MARK: - Unlock Option

struct UnlockOption: Identifiable {
    let id = UUID()
    let duration: Int // in minutes
    let price: Double

    var durationText: String {
        if duration >= 60 {
            let hours = duration / 60
            let mins = duration % 60
            if mins > 0 {
                return "\(hours)h \(mins)min"
            }
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        }
        return "\(duration) min"
    }

    var priceText: String {
        return String(format: "$%.2f", price)
    }
}

// MARK: - Wallet Manager

@MainActor
class WalletManager: ObservableObject {
    static let shared = WalletManager()

    @Published var balance: Double = 0.0
    @Published var transactions: [Transaction] = []
    @Published var totalInvested: Double = 0.0
    @Published var investmentsByType: [String: Double] = [
        "Bitcoin": 0.0,
        "Solana": 0.0,
        "S&P 500": 0.0,
        "T-Bills": 0.0
    ]

    // App Group for sharing with extensions
    private let appGroupID = "group.com.mathisligout.timeismoney"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private let balanceKey = "walletBalance"
    private let transactionsKey = "walletTransactions"
    private let investmentsKey = "walletInvestments"
    private let totalInvestedKey = "totalInvested"

    // Fixed unlock option
    let unlockOptions: [UnlockOption] = [
        UnlockOption(duration: 15, price: 0.50)
    ]

    var needsDeposit: Bool {
        balance < 1.0
    }

    var thisWeekInvested: Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return transactions
            .filter { $0.type == .unlock && $0.date >= weekAgo }
            .reduce(0) { $0 + $1.amount }
    }

    var thisMonthInvested: Double {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return transactions
            .filter { $0.type == .unlock && $0.date >= monthAgo }
            .reduce(0) { $0 + $1.amount }
    }

    init() {
        loadData()
        // Observe app becoming active to reload data (in case extension modified it)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadData()
            }
        }
    }

    // MARK: - Deposit

    func deposit(amount: Double) {
        balance += amount

        let transaction = Transaction(
            type: .deposit,
            amount: amount,
            description: "Added credit"
        )
        transactions.insert(transaction, at: 0)

        saveData()
    }

    // MARK: - Unlock (Pay to unlock app)

    func unlock(option: UnlockOption, appName: String, allocations: [String: Double]) -> Bool {
        guard balance >= option.price else { return false }

        balance -= option.price
        totalInvested += option.price

        for (investment, percentage) in allocations {
            let amount = option.price * (percentage / 100.0)
            investmentsByType[investment, default: 0.0] += amount
        }

        let transaction = Transaction(
            type: .unlock,
            amount: option.price,
            description: "Unlocked \(appName) for \(option.durationText)",
            allocations: allocations
        )
        transactions.insert(transaction, at: 0)

        saveData()
        return true
    }

    // MARK: - Persistence (App Group)

    private func saveData() {
        guard let defaults = sharedDefaults else { return }

        defaults.set(balance, forKey: balanceKey)
        defaults.set(totalInvested, forKey: totalInvestedKey)

        if let encoded = try? JSONEncoder().encode(transactions) {
            defaults.set(encoded, forKey: transactionsKey)
        }

        if let encoded = try? JSONEncoder().encode(investmentsByType) {
            defaults.set(encoded, forKey: investmentsKey)
        }

        defaults.synchronize()
    }

    func loadData() {
        guard let defaults = sharedDefaults else { return }

        balance = defaults.double(forKey: balanceKey)
        totalInvested = defaults.double(forKey: totalInvestedKey)

        if let data = defaults.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = decoded
        }

        if let data = defaults.data(forKey: investmentsKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            investmentsByType = decoded
        }
    }

    // MARK: - Reset (for testing)

    func reset() {
        balance = 0.0
        totalInvested = 0.0
        transactions = []
        investmentsByType = [
            "Bitcoin": 0.0,
            "Solana": 0.0,
            "S&P 500": 0.0,
            "T-Bills": 0.0
        ]
        saveData()
    }
}
