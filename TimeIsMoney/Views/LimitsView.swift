//
//  LimitsView.swift
//  TimeIsMoney
//

import SwiftUI
import FamilyControls

struct LimitsView: View {
    @StateObject private var limitsManager = LimitsManager()
    @State private var showingAddLimit = false

    var body: some View {
        NavigationStack {
            Group {
                if limitsManager.limits.isEmpty {
                    EmptyLimitsView(showingAddLimit: $showingAddLimit)
                } else {
                    LimitsList(limitsManager: limitsManager, showingAddLimit: $showingAddLimit)
                }
            }
            .navigationTitle("My Limits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddLimit = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddLimit) {
                AddLimitView(limitsManager: limitsManager)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyLimitsView: View {
    @Binding var showingAddLimit: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "hourglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Limits Set")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add a limit to block an app after a certain amount of usage time.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            Button(action: { showingAddLimit = true }) {
                Label("Add Limit", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top)

            Spacer()
        }
    }
}

// MARK: - Limits List

struct LimitsList: View {
    @ObservedObject var limitsManager: LimitsManager
    @Binding var showingAddLimit: Bool

    var body: some View {
        List {
            ForEach(limitsManager.limits) { limit in
                LimitRowView(limit: limit, limitsManager: limitsManager)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    limitsManager.removeLimit(limitsManager.limits[index])
                }
            }

            Section {
                Button(action: { showingAddLimit = true }) {
                    Label("Add Limit", systemImage: "plus.circle")
                }
            }
        }
    }
}

// MARK: - Limit Row

struct LimitRowView: View {
    let limit: AppLimit
    @ObservedObject var limitsManager: LimitsManager

    private var appsCount: Int {
        limit.selection.applicationTokens.count + limit.selection.categoryTokens.count
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(appsCount) app\(appsCount > 1 ? "s" : "")")
                    .font(.headline)

                Text("Blocked after \(limit.formattedTimeLimit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { limit.isActive },
                set: { _ in limitsManager.toggleLimit(limit) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Limit View

struct AddLimitView: View {
    @ObservedObject var limitsManager: LimitsManager
    @Environment(\.dismiss) var dismiss

    @State private var selection = FamilyActivitySelection()
    @State private var timeLimitMinutes: Int = 15
    @State private var isShowingPicker = false

    // Granularite de 1 minute jusqu'a 60 minutes
    private let timeOptions = Array(1...60)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: { isShowingPicker = true }) {
                        HStack {
                            Label("Apps to Block", systemImage: "app.badge.checkmark")
                            Spacer()
                            if selectedCount > 0 {
                                Text("\(selectedCount)")
                                    .foregroundStyle(.white)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue)
                                    .clipShape(Capsule())
                            }
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section("Temps avant blocage") {
                    Picker("Duree", selection: $timeLimitMinutes) {
                        ForEach(timeOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }
            }
            .navigationTitle("New Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        limitsManager.addLimit(selection: selection, minutes: timeLimitMinutes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedCount == 0)
                }
            }
            .familyActivityPicker(isPresented: $isShowingPicker, selection: $selection)
        }
    }

    private var selectedCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins > 0 {
                return "\(hours)h \(mins)min"
            }
            return "\(hours)h"
        }
        return "\(minutes) min"
    }
}

#Preview {
    LimitsView()
}
