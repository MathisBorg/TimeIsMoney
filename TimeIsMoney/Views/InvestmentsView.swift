//
//  InvestmentsView.swift
//  TimeIsMoney
//

import SwiftUI
import Charts

// MARK: - Investment Allocation Model

struct InvestmentAllocation: Identifiable, Codable {
    var id = UUID()
    let name: String
    var percentage: Double
    let colorName: String
    let icon: String

    var color: Color {
        switch colorName {
        case "orange": return .orange
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        default: return .gray
        }
    }

    init(id: UUID = UUID(), name: String, percentage: Double, colorName: String, icon: String) {
        self.id = id
        self.name = name
        self.percentage = percentage
        self.colorName = colorName
        self.icon = icon
    }
}

class InvestmentSettings: ObservableObject {
    static let shared = InvestmentSettings()

    @Published var allocations: [InvestmentAllocation] = []

    private let allocationsKey = "investmentAllocations"

    init() {
        loadAllocations()
    }

    var allocationsDictionary: [String: Double] {
        Dictionary(uniqueKeysWithValues: allocations.map { ($0.name, $0.percentage) })
    }

    func saveAllocations() {
        if let encoded = try? JSONEncoder().encode(allocations) {
            UserDefaults.standard.set(encoded, forKey: allocationsKey)
        }
    }

    func loadAllocations() {
        if let data = UserDefaults.standard.data(forKey: allocationsKey),
           let decoded = try? JSONDecoder().decode([InvestmentAllocation].self, from: data) {
            allocations = decoded
        } else {
            // Default allocations
            allocations = [
                InvestmentAllocation(name: "Bitcoin", percentage: 40, colorName: "orange", icon: "bitcoinsign.circle.fill"),
                InvestmentAllocation(name: "Solana", percentage: 20, colorName: "purple", icon: "s.circle.fill"),
                InvestmentAllocation(name: "S&P 500", percentage: 25, colorName: "blue", icon: "chart.line.uptrend.xyaxis.circle.fill"),
                InvestmentAllocation(name: "T-Bills", percentage: 15, colorName: "green", icon: "dollarsign.circle.fill")
            ]
        }
    }
}

// MARK: - Main View

struct InvestmentsView: View {
    @ObservedObject var wallet: WalletManager
    @StateObject private var settings = InvestmentSettings.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance Card
                    BalanceCard(wallet: wallet)

                    // Total Invested Card
                    TotalInvestedCard(wallet: wallet)

                    // Allocation Section with Pie Chart
                    AllocationSection(settings: settings)

                    // Portfolio Breakdown
                    PortfolioSection(settings: settings, wallet: wallet)

                    // Recent Transactions
                    RecentTransactionsSection(wallet: wallet)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Investments")
        }
    }
}

// MARK: - Balance Card

struct BalanceCard: View {
    @ObservedObject var wallet: WalletManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Available Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(String(format: "$%.2f", wallet.balance))
                    .font(.title)
                    .fontWeight(.bold)
            }

            Spacer()

            Image(systemName: "creditcard.fill")
                .font(.title)
                .foregroundStyle(.blue)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Total Invested Card

struct TotalInvestedCard: View {
    @ObservedObject var wallet: WalletManager

    var body: some View {
        VStack(spacing: 16) {
            Text("Total Invested")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(String(format: "$%.2f", wallet.totalInvested))
                .font(.system(size: 48, weight: .bold, design: .rounded))

            HStack(spacing: 20) {
                StatItem(title: "This Week", value: String(format: "$%.2f", wallet.thisWeekInvested))
                StatItem(title: "This Month", value: String(format: "$%.2f", wallet.thisMonthInvested))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
    }
}

// MARK: - Allocation Section with Pie Chart

struct AllocationSection: View {
    @ObservedObject var settings: InvestmentSettings
    @State private var showingAllocationEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Where Your Money Goes")
                    .font(.headline)
                Spacer()
                Button("Edit") {
                    showingAllocationEditor = true
                }
                .font(.subheadline)
            }

            HStack(spacing: 20) {
                // Pie Chart
                Chart(settings.allocations) { allocation in
                    SectorMark(
                        angle: .value("Percentage", allocation.percentage),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(allocation.color)
                    .cornerRadius(4)
                }
                .frame(width: 120, height: 120)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(settings.allocations) { allocation in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(allocation.color)
                                .frame(width: 10, height: 10)
                            Text(allocation.name)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(allocation.percentage))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .sheet(isPresented: $showingAllocationEditor) {
            AllocationEditorView(settings: settings)
        }
    }
}

// MARK: - Allocation Editor

struct AllocationEditorView: View {
    @ObservedObject var settings: InvestmentSettings
    @Environment(\.dismiss) var dismiss

    @State private var bitcoin: Double = 40
    @State private var solana: Double = 20
    @State private var sp500: Double = 25
    @State private var tbills: Double = 15

    var total: Double {
        bitcoin + solana + sp500 + tbills
    }

    var isValid: Bool {
        abs(total - 100) < 0.01
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(total))%")
                            .font(.headline)
                            .foregroundStyle(isValid ? .green : .red)
                    }
                }

                Section("Crypto") {
                    AllocationSlider(
                        icon: "bitcoinsign.circle.fill",
                        iconColor: .orange,
                        name: "Bitcoin",
                        value: $bitcoin
                    )

                    AllocationSlider(
                        icon: "s.circle.fill",
                        iconColor: .purple,
                        name: "Solana",
                        value: $solana
                    )
                }

                Section("Traditional") {
                    AllocationSlider(
                        icon: "chart.line.uptrend.xyaxis.circle.fill",
                        iconColor: .blue,
                        name: "S&P 500",
                        value: $sp500
                    )

                    AllocationSlider(
                        icon: "dollarsign.circle.fill",
                        iconColor: .green,
                        name: "T-Bills (USD Yield)",
                        value: $tbills
                    )
                }

                Section {
                    Button("Reset to Equal") {
                        bitcoin = 25
                        solana = 25
                        sp500 = 25
                        tbills = 25
                    }
                }
            }
            .navigationTitle("Edit Allocation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        settings.allocations = [
                            InvestmentAllocation(name: "Bitcoin", percentage: bitcoin, colorName: "orange", icon: "bitcoinsign.circle.fill"),
                            InvestmentAllocation(name: "Solana", percentage: solana, colorName: "purple", icon: "s.circle.fill"),
                            InvestmentAllocation(name: "S&P 500", percentage: sp500, colorName: "blue", icon: "chart.line.uptrend.xyaxis.circle.fill"),
                            InvestmentAllocation(name: "T-Bills", percentage: tbills, colorName: "green", icon: "dollarsign.circle.fill")
                        ]
                        settings.saveAllocations()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                // Load current values
                for allocation in settings.allocations {
                    switch allocation.name {
                    case "Bitcoin": bitcoin = allocation.percentage
                    case "Solana": solana = allocation.percentage
                    case "S&P 500": sp500 = allocation.percentage
                    case "T-Bills": tbills = allocation.percentage
                    default: break
                    }
                }
            }
        }
    }
}

struct AllocationSlider: View {
    let icon: String
    let iconColor: Color
    let name: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(name)
                Spacer()
                Text("\(Int(value))%")
                    .fontWeight(.medium)
                    .monospacedDigit()
            }

            Slider(value: $value, in: 0...100, step: 5)
                .tint(iconColor)
        }
    }
}

// MARK: - Portfolio Section

struct PortfolioSection: View {
    @ObservedObject var settings: InvestmentSettings
    @ObservedObject var wallet: WalletManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(settings.allocations) { allocation in
                    let amount = wallet.investmentsByType[allocation.name] ?? 0.0
                    InvestmentRow(
                        icon: allocation.icon,
                        iconColor: allocation.color,
                        name: allocation.name,
                        amount: String(format: "$%.2f", amount),
                        percentage: "\(Int(allocation.percentage))%"
                    )
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct InvestmentRow: View {
    let icon: String
    let iconColor: Color
    let name: String
    let amount: String
    let percentage: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40)

            Text(name)
                .font(.body)

            Spacer()

            VStack(alignment: .trailing) {
                Text(amount)
                    .font(.body)
                    .fontWeight(.medium)
                Text(percentage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Recent Transactions

struct RecentTransactionsSection: View {
    @ObservedObject var wallet: WalletManager

    var recentTransactions: [Transaction] {
        Array(wallet.transactions.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                if wallet.transactions.count > 5 {
                    Button("See All") {
                        // TODO: Show all transactions
                    }
                    .font(.subheadline)
                }
            }

            VStack(spacing: 12) {
                if recentTransactions.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text("No transactions yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("When you exceed your screen time limits, your investments will appear here.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                } else {
                    ForEach(recentTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                        if transaction.id != recentTransactions.last?.id {
                            Divider()
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, recentTransactions.isEmpty ? 0 : 16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(transaction.type == .deposit ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.type == .deposit ? "plus.circle.fill" : "hourglass")
                    .foregroundStyle(transaction.type == .deposit ? .green : .blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%@$%.2f", transaction.type == .deposit ? "+" : "-", transaction.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(transaction.type == .deposit ? .green : .primary)
        }
    }
}

#Preview {
    InvestmentsView(wallet: WalletManager.shared)
}
