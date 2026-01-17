//
//  AppUsageData.swift
//  TimeIsMoney
//
//  Created by TimeIsMoney
//

import Foundation
import FamilyControls
import ManagedSettings

/// Représente les données d'utilisation d'une app ou catégorie
struct AppUsageData: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let timeSpent: TimeInterval
    let iconName: String

    var formattedTime: String {
        let hours = Int(timeSpent) / 3600
        let minutes = (Int(timeSpent) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }
}

/// Représente une limite définie par l'utilisateur
struct AppLimit: Identifiable, Codable {
    let id: UUID
    var selection: FamilyActivitySelection
    var timeLimitMinutes: Int
    var isActive: Bool
    var createdAt: Date

    init(selection: FamilyActivitySelection, timeLimitMinutes: Int) {
        self.id = UUID()
        self.selection = selection
        self.timeLimitMinutes = timeLimitMinutes
        self.isActive = true
        self.createdAt = Date()
    }

    var formattedTimeLimit: String {
        let hours = timeLimitMinutes / 60
        let minutes = timeLimitMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes) min"
        }
    }
}

/// Catégories d'apps avec leurs icônes
enum AppCategory: String, CaseIterable {
    case social = "Réseaux sociaux"
    case games = "Jeux"
    case entertainment = "Divertissement"
    case productivity = "Productivité"
    case education = "Éducation"
    case other = "Autres"

    var iconName: String {
        switch self {
        case .social: return "person.2.fill"
        case .games: return "gamecontroller.fill"
        case .entertainment: return "play.tv.fill"
        case .productivity: return "briefcase.fill"
        case .education: return "book.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var color: String {
        switch self {
        case .social: return "blue"
        case .games: return "purple"
        case .entertainment: return "red"
        case .productivity: return "green"
        case .education: return "orange"
        case .other: return "gray"
        }
    }
}
