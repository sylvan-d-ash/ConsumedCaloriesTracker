//
//  Energy-ViewModel.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 05/06/2025.
//

import Foundation
import HealthKit

extension EnergyView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published private(set) var isLoading = false
        @Published private(set) var errorMessage: String?
        @Published private(set) var activeEnergyBurnedJoules: Double = 0.0
        @Published private(set) var restingEnergyBurnedJoules: Double = 0.0
        @Published private(set) var energyConsumedJoules: Double = 0.0

        var netEnergyJoules: Double {
            return energyConsumedJoules - (activeEnergyBurnedJoules + restingEnergyBurnedJoules)
        }

        private var energyFormatter: EnergyFormatter = {
            let formatter = EnergyFormatter()
            formatter.unitStyle = .long
            formatter.isForFoodEnergyUse = true // Default to kCal display
            formatter.numberFormatter.maximumFractionDigits = 0 // Usually calories are whole numbers
            return formatter
        }()

        private let healthKitManager: HealthKitManager

        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
        }

        func stringFromJoules(_ joules: Double) -> String {
            return energyFormatter.string(fromJoules: joules)
        }

        func refreshData() {
            guard !isLoading else { return }

            Task {
                isLoading = true
                errorMessage = nil

                do {
                    let activeJoules = try await healthKitManager.fetchDailyTotal(for: .activeEnergyBurned, unit: .joule())
                    let consumedJoules = try await healthKitManager.fetchDailyTotal(for: .dietaryEnergyConsumed, unit: .joule())
                    activeEnergyBurnedJoules = activeJoules
                    energyConsumedJoules = consumedJoules

                    let bmrInputs = try await healthKitManager.fetchBMRCalculationInputs()
                    let calculatedRestingBurnJoules = calculateBasalBurnForToday(from: bmrInputs) ?? 0.0
                    restingEnergyBurnedJoules = calculatedRestingBurnJoules
                } catch {
                    print("Error: \(error.localizedDescription)")
                    errorMessage = "Failed to load energy data: \(error.localizedDescription)"
                }

                isLoading = false
            }
        }

        private func calculateBasalBurnForToday(from inputs: HealthKitManager.BMRCalculationInputs) -> Double? {
            let heightInCentimeters = inputs.height.doubleValue(for: HKUnit(from: "cm"))
            let weightInKilograms = inputs.weight.doubleValue(for: .gramUnit(with: .kilo))

            let ageComponents = Calendar.current.dateComponents([.year], from: inputs.dateOfBirth, to: .now)
            guard let ageInYears = ageComponents.year else {
                errorMessage = "Cannot calculate BMR: Could not determine age."
                return nil
            }

            let bmrPerDayKcal = calculateBMR(weightInKilograms: weightInKilograms,
                                             heightInCentimeters: heightInCentimeters,
                                             ageInYears: ageInYears,
                                             biologicalSex: inputs.sex)

            // Convert BMR from Kcal/day to Joules/day for internal consistency before portioning
            let bmrPerDayJoules = HKQuantity(unit: .kilocalorie(), doubleValue: bmrPerDayKcal).doubleValue(for: .joule())

            let (startOfToday, endOfToday) = datesFromToday()
            let secondsInDay = endOfToday.timeIntervalSince(startOfToday)
            let percentOfDayComplete = Date().timeIntervalSince(startOfToday) / secondsInDay

            return bmrPerDayJoules * percentOfDayComplete
        }

        private func calculateBMR(weightInKilograms: Double, heightInCentimeters: Double, ageInYears: Int, biologicalSex: HKBiologicalSex) -> Double {
            var bmr: Double = 0
            if biologicalSex == .male || biologicalSex == .female {
                bmr = calculateBMR(weight: weightInKilograms, height: heightInCentimeters, age: ageInYears, sex: biologicalSex)
            } else {
                let maleBMR = calculateBMR(weight: weightInKilograms, height: heightInCentimeters, age: ageInYears, sex: .male)
                let femaleBMR = calculateBMR(weight: weightInKilograms, height: heightInCentimeters, age: ageInYears, sex: .female)
                bmr = (maleBMR + femaleBMR) / 2.0
            }
            return bmr
        }

        /**
         Using the Mifflin-St Jeor Equation (commonly used). It has the same bases for both Male and Female, with only the constant being different
         Male constant: (5)
         Female constant: (-161)
         */
        private func calculateBMR(weight: Double, height: Double, age: Int, sex: HKBiologicalSex) -> Double {
            let constant = (sex == .male) ? 5 : -161
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) + Double(constant)
        }

        private func datesFromToday() -> (Date, Date) {
            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: .now)
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
            return (startDate, endDate)
        }
    }
}
