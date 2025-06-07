//
//  LogWorkout-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import Foundation
import Combine
import HealthKit

extension HKUnit {
    var displayName: String {
        switch self {
        case .mile(): return "miles"
        case .meterUnit(with: .kilo): return "km"
        default: return "m"
        }
    }
}

extension LogWorkoutView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var selectedActivityType: HKWorkoutActivityType = .walking
        @Published var startDate = Date.now
        @Published var durationHours: Int = 0
        @Published var durationMinutes: Int = 30

        @Published var activeEnergy: Double?
        @Published var distance: Double?
        @Published var distanceUnit: HKUnit = .meterUnit(with: .kilo)

        @Published var isLoading = false
        @Published var errorMessage: String?
        @Published var successfullyAdded = false

        let availableTypes: [HKWorkoutActivityType] = HKWorkoutActivityType.commonActivityTypes
        let availableDistanceUnit: [HKUnit] = [.mile(), .meterUnit(with: .kilo), .meter()]

        private var endDate: Date {
            Calendar.current.date(byAdding: .minute, value: Int(durationMinutes), to: startDate) ?? startDate
        }

        var showDistanceField: Bool {
            HKWorkoutActivityType.distanceSupportingActivityTypes.contains(selectedActivityType)
        }

        var distanceUnitDisplay: String { distanceUnit.displayName }

        var numberFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0 // No decimals for minutes
            return formatter
        }

        private let healthKitManager: HealthKitManager

        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
        }

        func logWorkout() async {
            guard durationMinutes > 0 else {
                errorMessage = "Duration must be greater than 0 minutes"
                return
            }

            if let energy = activeEnergy, energy < 0 {
                errorMessage = "Active energy burned cannot be negative."
                return
            }
            if showDistanceField, let dist = distance, dist < 0 {
                errorMessage = "Distance cannot be negative."
                return
            }

            isLoading = true
            errorMessage = nil

            var energyQuantity: HKQuantity?
            if let energyValue = activeEnergy, energyValue > 0 {
                energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: energyValue)
            }

            var distanceQuantity: HKQuantity?
            if showDistanceField, let distanceValue = distance, distanceValue > 0 {
                distanceQuantity = HKQuantity(unit: distanceUnit, doubleValue: distanceValue)
            }

            do {
                try await healthKitManager.saveWorkout(
                    activityType: selectedActivityType,
                    startDate: startDate,
                    endDate: endDate,
                    totalEnergyBurned: energyQuantity,
                    totalDistance: distanceQuantity
                )

                successfullyAdded = true
            } catch {
                errorMessage = "Failed to log workout: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }
}
