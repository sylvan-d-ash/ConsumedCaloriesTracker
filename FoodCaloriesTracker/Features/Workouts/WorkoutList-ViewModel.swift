//
//  WorkoutList-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import Foundation
import Combine
import HealthKit

extension WorkoutsListView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var workouts: [WorkoutDisplayItem] = []
        @Published var isLoading = false
        @Published var errorMessage: String?

        private let healthKitManager: HealthKitManager

        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
        }

        func fetchWorkouts() async {
            guard !isLoading else { return }
            isLoading = true
            errorMessage = nil

            do {
                let hkWorkouts = try await healthKitManager.fetchWorkouts()
                workouts = hkWorkouts.map { WorkoutDisplayItem(hkWorkout: $0) }
            } catch {
                errorMessage = "Failed to load workouts: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }
}
