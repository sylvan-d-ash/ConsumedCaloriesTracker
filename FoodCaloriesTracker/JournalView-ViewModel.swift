//
//  JournalView-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Combine
import HealthKit

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
            Task {
                await fetchTodaysFoodLog()
            }
        }

        func onBecameActive() {
            Task {
                await fetchTodaysFoodLog()
            }
        }

        func foodItemSelectedFromPicker(_ item: FoodItem) {
            Task {
                await addFoodItemToJournal(item)
            }
        }
    }
}

private extension JournalView.ViewModel {
    func fetchTodaysFoodLog() async {
        isLoading = true
        errorMessage = nil

        do {
            let correlations = try await healthKitManager.fetchTodaysFoodCorrelations()
            loggedFoodItems = correlations.compactMap { correlation in
                guard let name = correlation.metadata?[HKMetadataKeyFoodType] as? String,
                      let energyConsumedType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)  else {
                    return nil
                }
                
                let energyConsumedSamples = correlation.objects(for: energyConsumedType)
                guard let energyConsumedSample = energyConsumedSamples.first as? HKQuantitySample else {
                    return nil
                }

                let joules: Double = energyConsumedSample.quantity.doubleValue(for: .joule())
                return FoodItem(name: name, joules: joules)
            }
        } catch {
            print("Error fetching food log: \(error)")
            errorMessage = "Failed to load journal: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func addFoodItemToJournal(_ item: FoodItem) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await healthKitManager.saveFoodCorrelation(name: item.name, joules: item.joules)
            loggedFoodItems.insert(item, at: 0)
        } catch {
            print("Error saving food item: \(error)")
            errorMessage = "Failed to save food: \(error.localizedDescription)"
        }
    }
}
