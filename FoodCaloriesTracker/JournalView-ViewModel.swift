//
//  JournalView-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Combine
import SwiftUI

extension JournalView {
    final class ViewModel: ObservableObject {
        static var energyFormatter: EnergyFormatter = {
            let formatter = EnergyFormatter()
            formatter.unitStyle = .long
            formatter.isForFoodEnergyUse = true
            formatter.numberFormatter.maximumFractionDigits = 2
            return formatter
        }()

        @Published var loggedFoodItems = [FoodItem]()
        @Published var showingFoodPicker = false
        @Published var isLoading = false
        @Published var errorMessage: String?

        private let healthKitManager: HealthKitManager

        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
        }

        func onAppear() {
            healthKitManager.requestAuthorizationAndLoadData()
            fetchTodaysFoodLog()
        }

        func handleScenePhaseChange(_ newPhase: ScenePhase) {
            if newPhase == .active {
                fetchTodaysFoodLog()
            }
        }

        func foodItemSelectedFromPicker(_ item: FoodItem) {
            saveFoodItemToHealthStore(item)
        }
    }
}

private extension JournalView.ViewModel {
    func fetchTodaysFoodLog() {
        isLoading = true
        errorMessage = nil
        healthKitManager.fetchTodaysFoodLog { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let items):
                    self?.loggedFoodItems = items
                case .failure(let error):
                    self?.errorMessage = "Failed to load journal: \(error.localizedDescription)"
                    print("Error fetching food log: \(error)")
                }
            }
        }
    }

    func saveFoodItemToHealthStore(_ foodItem: FoodItem) {
        isLoading = true // Or a different loading state for saving
        errorMessage = nil
        healthKitManager.saveFoodItem(foodItem) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false // Reset loading state
                switch result {
                case .success(let savedItem):
                    // Add to the top of the list optimistically or re-fetch
                    // For simplicity, let's prepend and assume it matches what's in HK
                    self?.loggedFoodItems.insert(savedItem, at: 0)
                    // Alternatively, re-fetch: self?.fetchTodaysFoodLog()
                case .failure(let error):
                    self?.errorMessage = "Failed to save food: \(error.localizedDescription)"
                    print("Error saving food item: \(error)")
                }
            }
        }
    }
}
