//
//  ProfileView-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Foundation
import Combine
import HealthKit

extension ProfileView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var userInfoItems: [ProfileItem] = []
        @Published var weightHeightItems: [ProfileItem] = []

        @Published var authorizationMessage: String?
        @Published var dataInteractionMessage: String?

        @Published var showingInputAlert = false
        @Published var alertInputType: ProfileItemType?
        @Published var alertInputValue: String = ""

        private let healthKitManager: HealthKitManager

        private let userInfoItemOrder: [ProfileItemType] = [.age, .sex, .bloodType]
        private let weightHeightItemOrder: [ProfileItemType] = [.weight, .height, .bmi]

        private var currentHeightMeters: Double?
        private var currentWeightKilograms: Double?

        var alertTitle: String {
            guard let type = alertInputType else { return "" }
            return "Update \(type.rawValue)"
        }

        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
            self.userInfoItems = self.userInfoItemOrder.map { ProfileItem(type: $0) }
            self.weightHeightItems = self.weightHeightItemOrder.map { ProfileItem(type: $0) }
        }

        func onViewAppear() {
            Task { await requestAuthorizationAndLoadProfileData() }
        }

        func handleProfileItemSelection(_ item: ProfileItem) {
            guard item.type.isEditable else { return }
            alertInputType = item.type
            showingInputAlert = true

            if item.type == .height, let currentHeightMeters = currentHeightMeters {
                alertInputValue = String(format: "%.2f", currentHeightMeters) // Edit in meters
            } else if item.type == .weight, let currentWeightKilograms = currentWeightKilograms {
                alertInputValue = String(format: "%.1f", currentWeightKilograms) // Edit in kg
            } else {
                alertInputValue = ""
            }
        }

        func saveNewValue() {
            guard let type = alertInputType else { return }
            guard let value = Double(alertInputValue.replacingOccurrences(of: ",", with: ".")) else {
                dataInteractionMessage = "Invalid input: \(alertInputValue) is not a valid number"
                return
            }

            dataInteractionMessage = nil

            Task {
                do {
                    switch type {
                    case .height:
                        try await healthKitManager.saveHeightInMeters(value)
                        await fetchAndUpdateUserHeight()
                    case .weight:
                        try await healthKitManager.saveWeightInKilograms(value)
                        await fetchAndUpdateUserWeight()
                    default: break
                    }
                } catch {
                    dataInteractionMessage = "Error saving \(type.displayName): \(error.localizedDescription)"
                }
            }
        }

        private func requestAuthorizationAndLoadProfileData() async {
            do {
                try await healthKitManager.requestAuthorizationAndLoadData()
                await fetchAllProfileData()
            } catch {
                authorizationMessage = "Authorization Error: \(error.localizedDescription)"
            }
        }

        private func fetchAllProfileData() async {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.fetchAndUpdateUserAge() }
                group.addTask { await self.fetchAndUpdateUserSex() }
                group.addTask { await self.fetchAndUpdateBloodType() }
                group.addTask { await self.fetchAndUpdateUserHeight() }
                group.addTask { await self.fetchAndUpdateUserWeight() }
            }
        }

        private func fetchAndUpdateUserAge() async {
            do {
                guard let dob = try healthKitManager.fetchDateOfBirth() else {
                    updateProfileItem(for: .age)
                    return
                }

                let ageComponents = Calendar.current.dateComponents([.year], from: dob, to: .now)
                let age = ageComponents.year ?? 0
                updateProfileItem(for: .age, value: "\(age) yrs")
            } catch {
                print("Error fetching age: \(error.localizedDescription)")
                updateProfileItem(for: .age)
            }
        }

        private func fetchAndUpdateUserSex() async {
            do {
                let sex = try healthKitManager.fetchBiologicalSex()
                let value: String
                switch sex {
                case .notSet: value = NSLocalizedString("Not set", comment: "")
                case .female: value = NSLocalizedString("Female", comment: "")
                case .male: value = NSLocalizedString("Male", comment: "")
                case .other: value = NSLocalizedString("Other", comment: "")
                @unknown default: value = NSLocalizedString("Not available", comment: "")
                }
                updateProfileItem(for: .sex, value: value)
            } catch {
                print("Error fetching sex: \(error.localizedDescription)")
                updateProfileItem(for: .sex)
            }
        }

        private func fetchAndUpdateBloodType() async {
            do {
                let bloodType = try healthKitManager.fetchBloodType()
                let value: String
                switch bloodType {
                case .aPositive: value = "A+"
                case .aNegative: value = "A-"
                case .bPositive: value = "B+"
                case .bNegative: value = "B-"
                case .abPositive: value = "AB+"
                case .abNegative: value = "AB-"
                case .oPositive: value = "O+"
                case .oNegative: value = "O-"
                case .notSet: value = NSLocalizedString("Not set", comment: "")
                @unknown default: value = NSLocalizedString("Not available", comment: "")
                }
                updateProfileItem(for: .bloodType, value: value)
            } catch {
                print("Error fetching blood type: \(error.localizedDescription)")
                updateProfileItem(for: .bloodType)
            }
        }

        private func fetchAndUpdateUserHeight() async {
            do {
                guard let quantity = try await healthKitManager.fetchMostRecentQuantitySample(for: .height) else {
                    updateProfileItem(for: .height)
                    currentHeightMeters = nil
                    calculateAndUpdateBMI()
                    return
                }
                let height = quantity.doubleValue(for: .meter())
                currentHeightMeters = height

                let formatter = LengthFormatter()
                formatter.isForPersonHeightUse = true
                updateProfileItem(for: .height, value: formatter.string(fromMeters: height))
                calculateAndUpdateBMI()
            } catch {
                print("Error fetching height: \(error.localizedDescription)")
                updateProfileItem(for: .height)
                currentHeightMeters = nil
                calculateAndUpdateBMI()
            }
        }

        private func fetchAndUpdateUserWeight() async {
            do {
                guard let quantity = try await healthKitManager.fetchMostRecentQuantitySample(for: .bodyMass) else {
                    updateProfileItem(for: .weight)
                    currentWeightKilograms = nil
                    calculateAndUpdateBMI()
                    return
                }
                let weight = quantity.doubleValue(for: .gramUnit(with: .kilo))
                currentWeightKilograms = weight

                let formatter = MassFormatter()
                formatter.isForPersonMassUse = true
                updateProfileItem(for: .weight, value: formatter.string(fromKilograms: weight))
                calculateAndUpdateBMI()
            } catch {
                print("Error fetching weight: \(error.localizedDescription)")
                updateProfileItem(for: .weight)
                currentWeightKilograms = nil
                calculateAndUpdateBMI()
            }
        }

        private func calculateAndUpdateBMI() {
            guard let height = currentHeightMeters, height > 0,
                  let weight = currentWeightKilograms, weight > 0 else {
                updateProfileItem(for: .bmi, value: NSLocalizedString("N/A", comment: "BMI not available due to missing height/weight"))
                return
            }
            let bmi = weight / (height * height)
            updateProfileItem(for: .bmi, value: String(format: "%.1f", bmi))
        }

        private func updateProfileItem(for type: ProfileItemType, value: String = NSLocalizedString("Not available", comment: "")) {
            if let index = userInfoItems.firstIndex(where: { $0.type == type }) {
                userInfoItems[index].value = value
            } else if let index = weightHeightItems.firstIndex(where: { $0.type == type }) {
                weightHeightItems[index].value = value
            }
        }
    }
}
