//
//  HealthKitManager.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Combine
import HealthKit

final class HealthKitManager: ObservableObject {
    @Published var authorizationError: String?
    @Published var dataFetchError: String?
    @Published var profileData: [ProfileItemType: ProfileItem] = [
        .age: ProfileItem(type: .age),
        .sex: ProfileItem(type: .sex),
        .height: ProfileItem(type: .height),
        .weight: ProfileItem(type: .weight),
        .bloodType: ProfileItem(type: .bloodType),
        .bmi: ProfileItem(type: .bmi),
    ]

    private let healthStore = HKHealthStore()
    private var currentHeightInMeters: Double?
    private var currentWeightInKilograms: Double?

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
              let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
              let biologicalType = HKObjectType.characteristicType(forIdentifier: .biologicalSex) else {
            return
        }

        let dataTypesToWrite: Set<HKSampleType> = [dietaryCaloriesEnergyType, activeEnergyBurnType, heightType, weightType]
        let dataTypesToRead: Set<HKObjectType> = [dietaryCaloriesEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalType, bloodType]

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

    func saveHeight(_ height: Double) {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            print("Height type not available for saving.")
            return
        }
        let heightQuantity = HKQuantity(unit: .meter(), doubleValue: height)
        let heightSample = HKQuantitySample(type: heightType, quantity: heightQuantity, start: .now, end: .now)

        healthStore.save(heightSample) { [weak self] (success, error) in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                if let error = error {
                    self.dataFetchError = "Error saving height: \(error.localizedDescription)"
                    print("Error saving height: \(error.localizedDescription)")
                    return
                }

                if success {
                    self.dataFetchError = nil
                    self.updateUserHeight()
                }
            }
        }
    }

    func saveWeight(_ weight: Double) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            print("Weight type not available for saving.")
            return
        }
        let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weight)
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: .now, end: .now)

        healthStore.save(weightSample) { [weak self] (success, error) in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                if let error = error {
                    self.dataFetchError = "Error saving weight: \(error.localizedDescription)"
                    print("Error saving weight: \(error.localizedDescription)")
                    return
                }
                if success {
                    self.dataFetchError = nil
                    self.updateUserWeight()
                }
            }
        }
    }

    func fetchTodaysFoodLog() async throws -> [FoodItem] {
        guard let foodCorrelationType = HKObjectType.correlationType(forIdentifier: .food) else {
            throw NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create food correlation type."])
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: foodCorrelationType,
                                      predicate: predicateForToday,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sortDescriptor]) {  _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let correlations = samples as? [HKCorrelation] else {
                    // No correlations found or type mismatch
                    continuation.resume(returning: [])
                    return
                }

                let foodItems = correlations.compactMap { Self.foodItem(from: $0) }
                continuation.resume(returning: foodItems)
            }
            self.healthStore.execute(query)
        }
    }

    func saveFoodItem(_ item: FoodItem) async throws -> FoodItem {
        guard let foodCorrelationType = HKObjectType.correlationType(forIdentifier: .food), let energyConsumedType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            throw NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create required HealthKit types for saving food!"])
        }

        let energyQuantity = HKQuantity(unit: .joule(), doubleValue: item.joules)
        let energySample = HKQuantitySample(type: energyConsumedType, quantity: energyQuantity, start: .now, end: .now)
        let samples: Set<HKSample> = [energySample]

        let correlationMetadata: [String: Any] = [HKMetadataKeyFoodType: item.name]
        let correlation = HKCorrelation(type: foodCorrelationType, start: .now, end: .now, objects: samples, metadata: correlationMetadata)

        return try await withCheckedThrowingContinuation { continuation in
            healthStore.save(correlation) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume(returning: item)
                    return
                }
                continuation.resume(throwing: NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to save food correlation without specific error message!"]))
            }
        }
    }

    enum ErrorCode: Int {
        case invalidType = 200
        case weightUnavailable = 202
        case heightUnavailable = 203
        case dobUnavailable = 204
        case sexUnavailable = 205
    }

    private var todayStartEndDates: (Date, Date?) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start)
        return (start, end)
    }

    private var predicateForToday: NSPredicate {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start)
        return HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
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
            updateProfileData(for: .age, value: "\(userAge)")
        } catch {
            print("Error fetching date of birth: \(error.localizedDescription)")
            updateProfileData(for: .age)
        }
    }

    private func updateUserSex() {
        do {
            var value: String = ""
            let sex = try healthStore.biologicalSex()
            switch sex.biologicalSex {
            case .notSet: value = NSLocalizedString("Not set", comment: "")
            case .female: value = NSLocalizedString("Female", comment: "")
            case .male: value = NSLocalizedString("Male", comment: "")
            case .other: value = NSLocalizedString("Other", comment: "")
            @unknown default: value = NSLocalizedString("Not available", comment: "")
            }

            updateProfileData(for: .sex, value: value)
        } catch {
            print("Error fetching biological sex: \(error.localizedDescription)")
            updateProfileData(for: .sex)
        }
    }

    private func updateBloodType() {
        do {
            var value = ""
            let bloodTypeObject = try healthStore.bloodType()
            switch bloodTypeObject.bloodType {
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
            updateProfileData(for: .bloodType, value: value)
        } catch {
            print("Error fetching blood type: \(error.localizedDescription)")
            updateProfileData(for: .bloodType)
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
                print("Error: No height sample to use")
                self.updateProfileData(for: .height)
                return
            }

            let height = sample.quantity.doubleValue(for: .meter())
            currentHeightInMeters = height

            let formatter = LengthFormatter()
            formatter.isForPersonHeightUse = true
            let heightValue = formatter.string(fromMeters: height)

            self.updateProfileData(for: .height, value: heightValue)
            self.calculateBMI()
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

            let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            currentWeightInKilograms = weight

            let formatter = MassFormatter()
            formatter.isForPersonMassUse = true
            let weightValue = formatter.string(fromKilograms: weight)

            self.updateProfileData(for: .weight, value: weightValue)
            self.calculateBMI()
        }
    }

    private func updateProfileData(for type: ProfileItemType, value: String = NSLocalizedString("Not available", comment: "")) {
        guard var item = profileData[type] else { return }
        item.value = value
        profileData[type] = item
    }

    private func calculateBMI() {
        guard let height = currentHeightInMeters, height > 0,
              let weight = currentWeightInKilograms, weight > 0 else {
            updateProfileData(for: .bmi)
            return
        }
        let bmi = weight / (height * height)
        let value = String(format: "%.2f", bmi)
        updateProfileData(for: .bmi, value: value)
    }

    private func fetchMostRecentSample(for identifier: HKQuantityTypeIdentifier) async throws -> HKQuantity? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw NSError(domain: "HealthKitManager", code: 201, userInfo: [NSLocalizedDescriptionKey: "Invalid quantity type identifier: \(identifier.rawValue)"])
        }

        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: .now, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: quantityType,
                                      predicate: predicate,
                                      limit: 1,
                                      sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples?.first as? HKQuantitySample)?.quantity)
            }
            self.healthStore.execute(query)
        }
    }

    // TODO: replace with fetchMostRecentSample()
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

    static private func foodItem(from correlation: HKCorrelation) -> FoodItem? {
        guard let name = correlation.metadata?[HKMetadataKeyFoodType] as? String,
              let energyConsumedType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)  else {
            return nil
        }

        let energyConsumedSamples = correlation.objects(for: energyConsumedType)
        guard let energyConsumedSample = energyConsumedSamples.first as? HKQuantitySample else {
            return nil
        }

        return FoodItem(name: name, joules: energyConsumedSample.quantity.doubleValue(for: .joule()))
    }
}

// MARK: - EnergyView
extension HealthKitManager {
    struct BMRCalculationInputs {
        let weightInKilograms: Double
        let heightInCentimeters: Double
        let ageInYears: Int
        let sex: HKBiologicalSex
    }
    struct BMRCalculationInputs2 {
        let weight: HKQuantity?
        let height: HKQuantity?
        let dateOfBirth: Date?
        let sex: HKBiologicalSex?
    }

    struct EnergySummary {
        var activeEnergyBurnedJoules: Double = 0.0
        var restingEnergyBurnedJoules: Double = 0.0
        var energyConsumedJoules: Double = 0.0

        var netEnergyJoules: Double {
            energyConsumedJoules - activeEnergyBurnedJoules - restingEnergyBurnedJoules
        }
    }

    // fetchSumOfSamplesToday
    func fetchDailyTotal(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw NSError(domain: "HealthKitManager", code: 201, userInfo: [NSLocalizedDescriptionKey: "Invalid quantity type identifier: \(identifier.rawValue)"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType,
                                          quantitySamplePredicate: predicateForToday,
                                          options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = statistics?.sumQuantity()
                let value = sum?.doubleValue(for: unit) ?? 0.0
                continuation.resume(returning: value)
            }
            self.healthStore.execute(query)
        }
    }

    func fetchBMRCalculationInputs() async throws -> BMRCalculationInputs2 {
        guard let weightQuantity = try await fetchMostRecentSample(for: .bodyMass) else {
            throw NSError(domain: "HealthKitManager", code: 203, userInfo: [NSLocalizedDescriptionKey: "Weight data not available."])
        }
        guard let heightQuantity = try await fetchMostRecentSample(for: .height) else {
            throw NSError(domain: "HealthKitManager", code: 204, userInfo: [NSLocalizedDescriptionKey: "Height data not available."])
        }
        guard let dob = try healthStore.dateOfBirthComponents().date else {
            throw NSError(domain: "HealthKitManager", code: 205, userInfo: [NSLocalizedDescriptionKey: "Date of birth not available."])
        }

        let sex = try healthStore.biologicalSex().biologicalSex
        guard sex != .notSet else {
            throw NSError(domain: "HealthKitManager", code: 207, userInfo: [NSLocalizedDescriptionKey: "Biological sex not set."])
        }

        return BMRCalculationInputs2(
            weight: weightQuantity,
            height: heightQuantity,
            dateOfBirth: dob,
            sex: sex
        )
    }

    // BMR Calculation (Harris-Benedict equation
    private func calculateBMR(inputs: BMRCalculationInputs) -> Double {
        var bmr: Double = 0
        if inputs.sex == .male {
            bmr = calculateBMR(weight: inputs.weightInKilograms, height: inputs.heightInCentimeters, age: inputs.ageInYears, constant: 5)
        } else if inputs.sex == .female {
            bmr = calculateBMR(weight: inputs.weightInKilograms, height: inputs.heightInCentimeters, age: inputs.ageInYears, constant: -161)
        } else {
            let maleBMR = calculateBMR(weight: inputs.weightInKilograms, height: inputs.heightInCentimeters, age: inputs.ageInYears, constant: 5)
            let femaleBMR = calculateBMR(weight: inputs.weightInKilograms, height: inputs.heightInCentimeters, age: inputs.ageInYears, constant: -161)
            bmr = (maleBMR + femaleBMR) / 2.0
        }
        return bmr
    }

    /**
     Using the Mifflin-St Jeor Equation (commonly used). It has the same bases for both Male and Female, with only the constant being different
     */
    private func calculateBMR(weight: Double, height: Double, age: Int, constant: Int) -> Double {
        return (10 * weight) + (6.25 * height) - (5 * Double(age)) + Double(constant)
    }

//    private func calculateRestingEnergyBurnedToday() async throws -> Double {
//        let inputs = try await fetchBMRCalculationInputs()
//        let bmrKcalPerDay = calculateBMR(inputs: inputs)
//        let (start, end) = todayStartEndDates
//
//        let secondsInFullDay: TimeInterval = end!.timeIntervalSince(start)
//        let secondsElapsedToday: TimeInterval = Date.now.timeIntervalSince(start)
//
//        guard secondsInFullDay > 0 else { return 0.0 } // Avoid division by zero
//        let percentOfDayComplete = max(0, min(1, secondsElapsedToday / secondsInFullDay))
//
//        let kilocaloriesBurnedToday = bmrKcalPerDay * percentOfDayComplete
//
//        // Convert Kcal to Joules for consistency if other values are in Joules
//        let restingBurnQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: kilocaloriesBurnedToday)
//        return restingBurnQuantity.doubleValue(for: .joule())
//    }
//
//    func fetchEnergySummary() async throws -> EnergySummary {
//        // Using async let to perform independent fetches concurrently
//        async let activeEnergyBurnedJoules = fetchDailyTotal(for: .activeEnergyBurned, unit: .joule())
//        async let energyConsumedJoules = fetchDailyTotal(for: .dietaryEnergyConsumed, unit: .joule())
//        async let restingEnergyBurnedJoules = calculateRestingEnergyBurnedToday()
//
//        // await all resuts
//        var summary = EnergySummary()
//        summary.activeEnergyBurnedJoules = try await activeEnergyBurnedJoules
//        summary.energyConsumedJoules = try await energyConsumedJoules
//        summary.restingEnergyBurnedJoules = try await restingEnergyBurnedJoules
//
//        return summary
//    }
}
