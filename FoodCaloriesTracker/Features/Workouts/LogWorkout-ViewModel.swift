//
//  LogWorkout-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import Foundation
import Combine
import HealthKit

extension LogWorkoutView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var selectedActivityType: HKWorkoutActivityType = .walking
        @Published var startDate = Date.now
        @Published var durationHours: Int = 0
        @Published var durationMinutes: Int = 30

        @Published var activeEnergy = ""
        @Published var distance = ""
        @Published var distanceUnit: HKUnit = .meterUnit(with: .kilo)

        @Published var isLoading = false
        @Published var errorMessage: String?

        let availableTypes: [HKWorkoutActivityType] = HKWorkoutActivityType.commonActivityTypes

        private var endDate: Date {
            Calendar.current.date(byAdding: .minute, value: Int(durationMinutes), to: startDate) ?? startDate
        }

        var showDistanceField: Bool {
            HKWorkoutActivityType.distanceSupportingActivityTypes.contains(selectedActivityType)
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

            if let energy = Double(activeEnergy), energy < 0 {
                errorMessage = "Active energy burned cannot be negative."
                return
            }
            if showDistanceField, let dist = Double(distance), dist < 0 {
                errorMessage = "Distance cannot be negative."
                return
            }

            isLoading = true
            errorMessage = nil

            var energyQuantity: HKQuantity?
            if let energyValue = Double(activeEnergy), energyValue > 0 {
                energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: energyValue)
            }

            var distanceQuantity: HKQuantity?
            if showDistanceField, let distanceValue = Double(distance), distanceValue > 0 {
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
            } catch {
                errorMessage = "Failed to log workout: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }
}
