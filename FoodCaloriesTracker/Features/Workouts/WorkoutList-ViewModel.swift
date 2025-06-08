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
        @Published var errorMessage: String?
        @Published private(set) var isLoading = false
        @Published private(set) var fetchedWorkouts: [HKWorkout] = []
        @Published private(set) var groupedWorkouts: [Date: [WorkoutDisplayItem]] = [:]
        @Published private(set) var sectionHeaders: [Date] = []

        private let healthKitManager: HealthKitManager

        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
        }

        func fetchWorkouts() async {
            guard !isLoading else { return }
            isLoading = true
            errorMessage = nil

            do {
                fetchedWorkouts = try await healthKitManager.fetchWorkouts()
                processAndDisplayWorkouts()
            } catch {
                errorMessage = "Failed to load workouts: \(error.localizedDescription)"
            }

            isLoading = false
        }

        func groupHeader(for date: Date) -> String {
            if Calendar.current.isDateInToday(date) { return "Today" }
            if Calendar.current.isDateInYesterday(date) { return "Yesterday" }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, d MMM"
            return dateFormatter.string(from: date)
        }

        private func processAndDisplayWorkouts() {
            let items = fetchedWorkouts.map { WorkoutDisplayItem(hkWorkout: $0) }
            var groupedItems: [Date: [WorkoutDisplayItem]] = [:]
            for item in items {
                let components = Calendar.current.dateComponents([.year, .month, .day], from: item.hkWorkout.startDate)
                let groupDate = Calendar.current.date(from: components) ?? item.hkWorkout.startDate
                groupedItems[groupDate, default: []].append(item)
            }
            self.groupedWorkouts = groupedItems
            self.sectionHeaders = Array(groupedItems.keys).sorted(by: >)
        }
    }
}
