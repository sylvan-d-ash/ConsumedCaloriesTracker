//
//  HealthKitManager.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Combine
import HealthKit

final class HealthKitManager: ObservableObject {
    @Published var authorizationStatus: HKAuthorizationStatus?
    @Published var authorizationError: String?
    @Published var dataFetchError: String?
    @Published var profileData: [ProfileItemType: ProfileItemData] = [
        .age: ProfileItemData(type: .age),
        .sex: ProfileItemData(type: .sex),
        .height: ProfileItemData(type: .height),
        .weight: ProfileItemData(type: .weight),
    ]

    private let healthStore = HKHealthStore()

//    private var dataTypesToWrite: Set<HKSampleType> {
//        guard let dietaryCaloriesEnergyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
//              let activeEnergyBurnType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
//              let heightType = HKQuantityType.quantityType(forIdentifier: .height),
//              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
//            return []
//        }
//        return [dietaryCaloriesEnergyType, activeEnergyBurnType, heightType, weightType]
//    }

//    private var dataTypesToRead: Set<HKObjectType> {
//        guard let dietaryCaloriesEnergyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
//              let activeEnergyBurnType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
//              let heightType = HKQuantityType.quantityType(forIdentifier: .height),
//              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
//              let birthdayType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
//              let biologicalType = HKObjectType.characteristicType(forIdentifier: .biologicalSex) else {
//            return []
//        }
//        return [dietaryCaloriesEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalType]
//    }

    func requestAuthorizationAndLoadData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            self.authorizationError = "HealthKit is not available on this device."
            return
        }

        guard let dietaryCaloriesEnergyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
              let activeEnergyBurnType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let heightType = HKQuantityType.quantityType(forIdentifier: .height),
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
              let birthdayType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
              let biologicalType = HKObjectType.characteristicType(forIdentifier: .biologicalSex) else {
            return
        }

        let dataTypesToWrite: Set<HKSampleType> = [dietaryCaloriesEnergyType, activeEnergyBurnType, heightType, weightType]
        let dataTypesToRead: Set<HKObjectType> = [dietaryCaloriesEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalType]

        healthStore.requestAuthorization(toShare: dataTypesToWrite, read: dataTypesToRead) { [weak self] (success, error) in
            DispatchQueue.main.async {
                guard let `self` = self else { return }

                if let error {
                    self.authorizationError = "Authorization failed: \(error.localizedDescription)"
                    print("HealthKit access not granted. If using a simulator, try on a physical device. Error: \(error.localizedDescription)")
                    return
                }
                if success {
                    self.authorizationError = nil
                    self.updateUserAge()
                    self.updateUserSex()
                    self.updateUserHeight()
                    self.updateUserWeight()
                } else {
                    self.authorizationError = "Authorization was not granted. Please check Settings."
                }
            }
        }
    }

    private func updateUserAge() {
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents().date
            guard let dateOfBirth else {
                updateProfileData(for: .age)
                return
            }

            let components = Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now)
            let userAge = components.year ?? 0
            let ageValue = NumberFormatter.localizedString(from: userAge as NSNumber, number: .none)
            updateProfileData(for: .age, value: ageValue)
        } catch {
            print("Error fetching date of birth: \(error.localizedDescription)")
            updateProfileData(for: .age)
        }
    }

    private func updateUserSex() {
        do {
            let sex = try healthStore.biologicalSex()
            updateProfileData(for: .sex, value: sex.biologicalSex.rawValue == 1 ? "Female" : "Male")
        } catch {
            print("Error fetching biological sex: \(error.localizedDescription)")
            updateProfileData(for: .sex)
        }
    }

    private func updateUserHeight() {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            print("Height type not available!")
            return
        }

        getMostRecentSample(for: heightType) { [weak self] sample, error in
            guard let `self` = self else { return }

            if let error {
                print("Error fetching height: \(error.localizedDescription)")
                self.updateProfileData(for: .height)
                return
            }

            guard let sample else {
                self.updateProfileData(for: .height)
                return
            }

            let quantity = sample.quantity
            print("Inch: \(quantity.doubleValue(for: HKUnit.inch())) | Meters: \(quantity.doubleValue(for: HKUnit.meter())) | Feet: \(quantity.doubleValue(for: HKUnit.foot()))")

            // value
            let height = sample.quantity.doubleValue(for: HKUnit.inch())
            let heightValue = NumberFormatter.localizedString(from: height as NSNumber, number: .decimal)

            // unit label
            let formatter = LengthFormatter()
            formatter.unitStyle = .long
            let unitString = formatter.unitString(fromValue: 1, unit: .inch)
            let unitLabel = String(format: NSLocalizedString("Height (@)", comment: ""), unitString)

            self.updateProfileData(for: .height, unitLabel: unitLabel, value: heightValue)
        }
    }

    private func updateUserWeight() {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            print("Weight type not available")
            return
        }

        getMostRecentSample(for: weightType) { [weak self] (sample, error) in
            guard let `self` = self else { return }

            if let error {
                print("Error fetching most recent weight sample: \(error.localizedDescription)")
                self.updateProfileData(for: .weight)
                return
            }

            guard let sample else {
                self.updateProfileData(for: .weight)
                return
            }

            // value
            let weight = sample.quantity.doubleValue(for: HKUnit.pound())
            let weightValue = NumberFormatter.localizedString(from: weight as NSNumber, number: .decimal)

            // unit label
            let formatter = MassFormatter()
            formatter.unitStyle = .long
            let unitString = formatter.unitString(fromValue: 1, unit: .pound)
            let unitLabel = String(format: NSLocalizedString("Weight (%@)", comment: ""), unitString)

            self.updateProfileData(for: .weight, unitLabel: unitLabel, value: weightValue)
        }
    }

    private func updateProfileData(for type: ProfileItemType, unitLabel: String? = nil, value: String = NSLocalizedString("Not available", comment: "")) {
        guard var item = profileData[type] else { return }
        if let unitLabel {
            item.unitLabel = unitLabel
        }
        item.value = value
        profileData[type] = item
    }

    private func getMostRecentSample(for sampleType: HKSampleType, completion: @escaping (HKQuantitySample?, Error?) -> Void) {
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: .distantPast, end: .now, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                guard let samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                    completion(nil, error)
                    return
                }
                completion(mostRecentSample, nil)
            }
        }
        healthStore.execute(query)
    }
}
