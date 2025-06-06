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
        @Published var selectedDistanceUnit: UnitLength = .kilometers

        @Published var isSaving = false
        @Published var errorMessage: String?

        private let healthKitManager: HealthKitManager
        
        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
        }
    }
}
