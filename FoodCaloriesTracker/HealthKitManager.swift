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
        .height: ProfileItemData(type: .height, unitLabel: "Height ()"),
        .weight: ProfileItemData(type: .weight, unitLabel: "Weight ()"),
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
                    self.updateUserHeight()
                    self.updateUserWeight()
                } else {
                    self.authorizationError = "Authorization was not granted. Please check Settings."
                }
            }
        }
    }

    private func updateUserAge() {
        //
    }

    private func updateUserHeight() {
        //
    }

    private func updateUserWeight() {
        //
    }
}
