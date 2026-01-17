//
//  ProfileView.swift
//  TimeIsMoney
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var wallet: WalletManager
    @Binding var showingAddCredit: Bool

    var body: some View {
        NavigationStack {
            List {
                // Balance Section
                Section {
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

                        Button("Add Credit") {
                            showingAddCredit = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                }

                // Settings
                Section("Settings") {
                    NavigationLink {
                        NotificationsSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }

                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                }

                // Investment Preferences
                Section("Investment Preferences") {
                    NavigationLink {
                        InvestmentPreferencesView()
                    } label: {
                        Label("Default Investment", systemImage: "dollarsign.circle")
                    }

                    NavigationLink {
                        LinkedAccountsView()
                    } label: {
                        Label("Linked Accounts", systemImage: "link")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                // Support
                Section("Support") {
                    NavigationLink {
                        HelpCenterView()
                    } label: {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }

                    Button {
                        // TODO: Open email
                    } label: {
                        Label("Contact Us", systemImage: "envelope")
                    }
                }

                // Debug Section (for testing)
                #if DEBUG
                Section("Debug") {
                    Button("Reset All Data") {
                        wallet.reset()
                    }
                    .foregroundStyle(.red)

                    Button("Simulate Unlock Transaction") {
                        let settings = InvestmentSettings.shared
                        _ = wallet.unlock(
                            option: UnlockOption(duration: 15, price: 0.50),
                            appName: "Instagram",
                            allocations: settings.allocationsDictionary
                        )
                    }
                }
                #endif
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Placeholder Views

struct NotificationsSettingsView: View {
    @State private var dailyReminder = true
    @State private var limitReached = true
    @State private var weeklyReport = false

    var body: some View {
        List {
            Section("Alerts") {
                Toggle("Daily Reminder", isOn: $dailyReminder)
                Toggle("Limit Reached", isOn: $limitReached)
            }

            Section("Reports") {
                Toggle("Weekly Report", isOn: $weeklyReport)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct AppearanceSettingsView: View {
    @State private var selectedTheme = 0

    var body: some View {
        List {
            Section("Theme") {
                Picker("Appearance", selection: $selectedTheme) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Appearance")
    }
}

struct InvestmentPreferencesView: View {
    @State private var selectedInvestment = 0

    var body: some View {
        List {
            Section("Default Investment Type") {
                Picker("Investment", selection: $selectedInvestment) {
                    Text("Bitcoin").tag(0)
                    Text("ETF S&P 500").tag(1)
                    Text("Savings").tag(2)
                }
            }

            Section(footer: Text("Choose where your money goes when you exceed your screen time limits.")) {
                EmptyView()
            }
        }
        .navigationTitle("Investment")
    }
}

struct LinkedAccountsView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Label("Bank Account", systemImage: "building.columns")
                    Spacer()
                    Text("Not linked")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Crypto Wallet", systemImage: "bitcoinsign.circle")
                    Spacer()
                    Text("Not linked")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Link New Account") {
                    // TODO: Link account
                }
            }
        }
        .navigationTitle("Linked Accounts")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content will be displayed here.")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service content will be displayed here.")
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

struct HelpCenterView: View {
    var body: some View {
        List {
            Section("FAQ") {
                NavigationLink("How do limits work?") {
                    Text("Limits explanation...")
                        .padding()
                        .navigationTitle("Limits")
                }

                NavigationLink("How are investments made?") {
                    Text("Investment explanation...")
                        .padding()
                        .navigationTitle("Investments")
                }

                NavigationLink("How to cancel a limit?") {
                    Text("Cancellation explanation...")
                        .padding()
                        .navigationTitle("Cancel Limit")
                }
            }
        }
        .navigationTitle("Help Center")
    }
}

#Preview {
    ProfileView(wallet: WalletManager.shared, showingAddCredit: .constant(false))
}
