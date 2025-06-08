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
    let dateRange: String
    let duration: String
    let energyBurned: String?
    let distance: String?

    var activityType: HKWorkoutActivityType { hkWorkout.workoutActivityType }
    var name: String { hkWorkout.workoutActivityType.displayName }
    var iconName: String { hkWorkout.workoutActivityType.iconName }

    static let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true // "Today" or "Yesterday"
        return formatter
    }()

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM" // 8 Jun
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
        self.dateRange = Self.formatDate(hkWorkout.startDate)
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

    private static func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) || Calendar.current.isDateInYesterday(date) {
            return relativeDateFormatter.string(from: date)
        }
        return shortDateFormatter.string(from: date)
    }
}

extension WorkoutDisplayItem {
    static func createSampleWorkouts() -> [HKWorkout] {
        var workouts: [HKWorkout] = []

        // Workout 1: Running
        let runEnergy = HKQuantity(unit: .kilocalorie(), doubleValue: 350.0)
        let runDistance = HKQuantity(unit: .meter(), doubleValue: 5000.0) // 5 km
        let runStart = Calendar.current.date(byAdding: .day, value: -2, to: Date())! // 2 days ago
        let runEnd = runStart.addingTimeInterval(30 * 60) // 30 min duration
        let runWorkout = HKWorkout(activityType: .running,
                                   start: runStart,
                                   end: runEnd,
                                   duration: runEnd.timeIntervalSince(runStart),
                                   totalEnergyBurned: runEnergy,
                                   totalDistance: runDistance,
                                   metadata: [HKMetadataKeyIndoorWorkout: false]) // Outdoor run
        workouts.append(runWorkout)

        // Workout 2: Strength Training
        let strengthEnergy = HKQuantity(unit: .kilocalorie(), doubleValue: 220.0)
        let strengthStart = Calendar.current.date(byAdding: .day, value: -1, to: Date())! // Yesterday
        let strengthEnd = strengthStart.addingTimeInterval(45 * 60) // 45 min duration
        let strengthWorkout = HKWorkout(activityType: .traditionalStrengthTraining,
                                        start: strengthStart,
                                        end: strengthEnd,
                                        duration: strengthEnd.timeIntervalSince(strengthStart),
                                        totalEnergyBurned: strengthEnergy,
                                        totalDistance: nil, // No distance for strength
                                        metadata: nil)
        workouts.append(strengthWorkout)

        // Workout 3: Walking
        let walkEnergy = HKQuantity(unit: .kilocalorie(), doubleValue: 150.0)
        let walkDistance = HKQuantity(unit: .meter(), doubleValue: 3200.0) // 3.2 km
        let walkStart = Calendar.current.date(byAdding: .hour, value: -3, to: Date())! // 3 hours ago today
        let walkEnd = walkStart.addingTimeInterval(40 * 60) // 40 min duration
        let walkWorkout = HKWorkout(activityType: .walking,
                                    start: walkStart,
                                    end: walkEnd,
                                    duration: walkEnd.timeIntervalSince(walkStart),
                                    totalEnergyBurned: walkEnergy,
                                    totalDistance: walkDistance,
                                    metadata: nil)
        workouts.append(walkWorkout)

        // Workout 4: HIIT (High Intensity Interval Training)
        let hiitEnergy = HKQuantity(unit: .kilocalorie(), doubleValue: 180.0)
        let hiitStart = Calendar.current.date(byAdding: .day, value: -3, to: Date())! // 3 days ago
        let hiitEnd = hiitStart.addingTimeInterval(20 * 60) // 20 min duration
        let hiitWorkout = HKWorkout(activityType: .highIntensityIntervalTraining,
                                    start: hiitStart,
                                    end: hiitEnd,
                                    duration: hiitEnd.timeIntervalSince(hiitStart),
                                    totalEnergyBurned: hiitEnergy,
                                    totalDistance: nil,
                                    metadata: nil)
        workouts.append(hiitWorkout)

        return workouts
    }

    static func createSampleWorkoutDisplayItems() -> [WorkoutDisplayItem] {
        let mockHKWorkouts = createSampleWorkouts()
        return mockHKWorkouts.map { WorkoutDisplayItem(hkWorkout: $0) }
    }
}
