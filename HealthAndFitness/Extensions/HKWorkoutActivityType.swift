//
//  HKWorkoutActivityType.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 06/06/2025.
//

import Foundation
import HealthKit
import SwiftUI

extension HKWorkoutActivityType: @retroactive Identifiable {
    public var id: UInt { self.rawValue }

    var displayName: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .traditionalStrengthTraining: return "Traditional Strength"
        case .functionalStrengthTraining: return "Functional Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing, .stairs, .stepTraining: return "Stairs/Step Training"
        case .coreTraining: return "Core Training"
        case .dance, .danceInspiredTraining, .cardioDance: return "Dance"
        case .pilates: return "Pilates"
        case .cooldown: return "Cooldown"
        case .flexibility: return "Flexibility"
        case .mindAndBody: return "Mind & Body"
        case .other: return "Other Workout"

        default:
            // Create a somewhat readable name from the enum case
            // This is a basic attempt and might need refinement
            let name = String(describing: self)
            return name.replacingOccurrences(of: "HKWorkoutActivityType", with: "")
                .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression, range: name.range(of: name))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .capitalized
        }
    }

    var iconName: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .yoga: return "figure.yoga"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "figure.hiking"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        case .stairClimbing, .stairs, .stepTraining: return "figure.stairs"
        case .coreTraining: return "figure.core.training"
        case .cardioDance: return "figure.dance"
        case .pilates: return "figure.pilates"
        case .cooldown: return "figure.cooldown"
        case .flexibility: return "figure.flexibility"
        case .mindAndBody: return "brain.head.profile"
        case .other: return "figure.mixed.cardio" // A generic "activity" icon
            // Add more icons
        default: return "figure.mixed.cardio" // Fallback icon
        }
    }

    var iconColor: Color {
        switch self {
        case .walking, .running, .hiking:
            return .orange
        case .traditionalStrengthTraining, .functionalStrengthTraining, .highIntensityIntervalTraining, .coreTraining:
            return .blue
        case .mindAndBody, .yoga, .pilates, .flexibility:
            return .purple
        case .cycling, .elliptical, .cardioDance, .swimming:
            return .green
        default:
            return .yellow
        }
    }

    static var commonActivityTypes: [HKWorkoutActivityType] {
        return [
            .walking, .running, .cycling, .traditionalStrengthTraining, .functionalStrengthTraining,  .highIntensityIntervalTraining,
            .yoga, .hiking, .swimming, .elliptical, .rowing, .stairClimbing, .coreTraining, .cardioDance, .pilates, .flexibility, .mindAndBody, .cooldown, .other
        ]
    }

    static var distanceSupportingActivityTypes: Set<HKWorkoutActivityType> = [
        .walking, .running, .cycling, .swimming, .hiking, .rowing, .elliptical,
    ]
}
