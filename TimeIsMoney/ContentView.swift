//
//  ContentView.swift
//  TimeIsMoney
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct ContentView: View {
    @StateObject private var authManager = AuthorizationManager()
    @StateObject private var wallet = WalletManager.shared
    @StateObject private var unlockManager = UnlockManager.shared
    @State private var showingAddCredit = false

    var body: some View {
        Group {
            switch authManager.authorizationStatus {
            case .notDetermined:
                AuthorizationRequestView(authManager: authManager)
            case .denied:
                AuthorizationDeniedView()
            case .approved:
                MainTabView(wallet: wallet, unlockManager: unlockManager)
                    .onAppear {
                        // Show add credit if balance is too low
                        if wallet.needsDeposit {
                            showingAddCredit = true
                        }
                    }
                    .fullScreenCover(isPresented: $showingAddCredit) {
                        AddCreditView(wallet: wallet, isPresented: $showingAddCredit)
                    }
            @unknown default:
                AuthorizationRequestView(authManager: authManager)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @ObservedObject var wallet: WalletManager
    @ObservedObject var unlockManager: UnlockManager
    @State private var showingAddCredit = false
    @State private var showingUnlock = false

    var body: some View {
        TabView {
            LimitsView()
                .tabItem {
                    Label("Limits", systemImage: "hourglass")
                }

            InvestmentsView(wallet: wallet)
                .tabItem {
                    Label("Investments", systemImage: "chart.line.uptrend.xyaxis")
                }

            ProfileView(wallet: wallet, showingAddCredit: $showingAddCredit)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .sheet(isPresented: $showingAddCredit) {
            AddCreditView(wallet: wallet, isPresented: $showingAddCredit)
        }
        .sheet(isPresented: $showingUnlock) {
            UnlockView(
                appName: "Blocked App",
                onUnlock: { option in
                    let settings = InvestmentSettings.shared
                    let success = wallet.unlock(
                        option: option,
                        appName: "App",
                        allocations: settings.allocationsDictionary
                    )
                    if success {
                        unlockManager.performUnlock(duration: option.duration)
                    }
                    return success
                },
                onDismiss: {
                    showingUnlock = false
                    unlockManager.clearPendingUnlock()
                }
            )
        }
        .onAppear {
            checkPendingUnlock()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkPendingUnlock()
        }
    }

    private func checkPendingUnlock() {
        if unlockManager.hasPendingUnlock {
            showingUnlock = true
        }
    }
}

// MARK: - Unlock Manager

@MainActor
class UnlockManager: ObservableObject {
    static let shared = UnlockManager()

    private let appGroupID = "group.com.mathisligout.timeismoney"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    private let store = ManagedSettingsStore()

    var hasPendingUnlock: Bool {
        sharedDefaults?.bool(forKey: "pendingUnlock") ?? false
    }

    func clearPendingUnlock() {
        sharedDefaults?.set(false, forKey: "pendingUnlock")
        sharedDefaults?.removeObject(forKey: "pendingUnlockType")
        sharedDefaults?.synchronize()
    }

    func performUnlock(duration: Int) {
        // Clear the shield temporarily
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        clearPendingUnlock()

        // Schedule re-blocking after the duration
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(duration * 60)) { [weak self] in
            self?.reapplyShields()
        }
    }

    private func reapplyShields() {
        // Reload limits and reapply shields
        // This will be handled by LimitsManager when the app is active
        NotificationCenter.default.post(name: .reapplyShields, object: nil)
    }
}

extension Notification.Name {
    static let reapplyShields = Notification.Name("reapplyShields")
}

// MARK: - Authorization Manager

@MainActor
class AuthorizationManager: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                authorizationStatus = .approved
            } catch {
                authorizationStatus = .denied
            }
        }
    }
}

// MARK: - Authorization Request View

struct AuthorizationRequestView: View {
    @ObservedObject var authManager: AuthorizationManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("TimeIsMoney")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("To block apps and set limits, please allow access to Screen Time.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                authManager.requestAuthorization()
            }) {
                Text("Allow Access")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Authorization Denied View

struct AuthorizationDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)

            Text("Access Denied")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("To use TimeIsMoney, please allow access in Settings > Screen Time.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    ContentView()
}
