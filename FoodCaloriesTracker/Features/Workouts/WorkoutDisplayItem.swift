//
//  WorkoutDisplayItem.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import Foundation
import HealthKit

struct WorkoutDisplayItem: Identifiable {
    let id: UUID
    let hkWorkout: HKWorkout
    let activityType: HKWorkoutActivityType
    let name: String
    let iconName: String
    let dateRange: String
    let duration: String
    let energyBurned: String?
    let distance: String?

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated // "1h 23m" or "30m 15s"
        return formatter
    }()

    static let energyFormatter: EnergyFormatter = {
        let formatter = EnergyFormatter()
        formatter.unitStyle = .short // "kcal"
        formatter.isForFoodEnergyUse = false
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()

    static let distanceFormatter: LengthFormatter = {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short // "mi" or "km"
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter
    }()

    init(hkWorkout: HKWorkout) {
        self.id = hkWorkout.uuid
        self.hkWorkout = hkWorkout
        self.activityType = hkWorkout.workoutActivityType

        let (name, icon) = Self.activityTypeDetails(hkWorkout.workoutActivityType)
        self.name = name
        self.iconName = icon
        self.dateRange = "\(Self.dateFormatter.string(from: hkWorkout.startDate))"
        self.duration = Self.durationFormatter.string(from: hkWorkout.duration) ?? "N/A"

        //if let totalEnergy = hkWorkout.statistics(for: HKQuantityType(.activeEnergyBurned)) {
        if let totalEnergy = hkWorkout.totalEnergyBurned {
            self.energyBurned = Self.energyFormatter.string(fromValue: totalEnergy.doubleValue(for: .kilocalorie()), unit: .kilocalorie)
        } else {
            self.energyBurned = nil
        }

        if let totalDistance = hkWorkout.totalDistance {
            self.distance = Self.distanceFormatter.string(fromMeters: totalDistance.doubleValue(for: .meter()))
        } else {
            self.distance = nil
        }
    }

    static func activityTypeDetails(_ activityType: HKWorkoutActivityType) -> (name: String, icon: String) {
        switch activityType {
        case .running: return ("Running", "figure.run")
        case .walking: return ("Walking", "figure.walk")
        case .cycling: return ("Cycling", "figure.outdoor.cycle")
        case .highIntensityIntervalTraining: return ("HIIT", "flame.fill")
        case .yoga: return ("Yoga", "figure.yoga")
        case .swimming: return ("Swimming", "figure.pool.swim")
        case .hiking: return ("Hiking", "figure.hiking")
        case .traditionalStrengthTraining: return ("Traditional Strength", "figure.strengthtraining.traditional") //dumbbell.fill
        case .functionalStrengthTraining: return ("Functional Strength", "figure.strengthtraining.functional")
        case .elliptical: return ("Elliptical", "figure.elliptical")
        case .rowing: return ("Rowing", "figure.rower")
        case .stairClimbing: return ("Stair Climbing", "figure.stairs")
        default: return ("Workout", "figure.mixed.cardio")
        }
    }
}
