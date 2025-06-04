//
//  JournalView-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Combine
import SwiftUI

extension JournalView {
    @MainActor
    final class ViewModel: ObservableObject {
        static var energyFormatter: EnergyFormatter = {
            let formatter = EnergyFormatter()
            formatter.unitStyle = .long
            formatter.isForFoodEnergyUse = true
            formatter.numberFormatter.maximumFractionDigits = 2
            return formatter
        }()

        @Published var loggedFoodItems = [FoodItem]()
        @Published var isLoading = false
        @Published var errorMessage: String?

        private let healthKitManager: HealthKitManager

        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
        }

        func onAppear() {
            healthKitManager.requestAuthorizationAndLoadData()
            Task {
                await fetchTodaysFoodLog()
            }
        }

        func handleScenePhaseChange(_ newPhase: ScenePhase) {
            if newPhase == .active {
                Task {
                    await fetchTodaysFoodLog()
                }
            }
        }

        func foodItemSelectedFromPicker(_ item: FoodItem) {
            Task {
                await saveFoodItemToHealthStore(item)
            }
        }
    }
}

private extension JournalView.ViewModel {
    func fetchTodaysFoodLog() async {
        isLoading = true
        errorMessage = nil

        do {
            loggedFoodItems = try await healthKitManager.fetchTodaysFoodLog()
        } catch {
            print("Error fetching food log: \(error)")
            errorMessage = "Failed to load journal: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func saveFoodItemToHealthStore(_ foodItem: FoodItem) async {
        isLoading = true
        errorMessage = nil

        do {
            let item = try await healthKitManager.saveFoodItem(foodItem)
            loggedFoodItems.insert(item, at: 0)
        } catch {
            errorMessage = "Failed to save food: \(error.localizedDescription)"
            print("Error saving food item: \(error)")
        }

        isLoading = false
    }
}
