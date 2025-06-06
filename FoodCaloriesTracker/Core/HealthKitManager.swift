//
//  HealthKitManager.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Combine
import HealthKit

enum HealthKitManagerError: Error, LocalizedError {
    case invalidQuantityTypeIdentifier(String)
    case healthDataNotAvailable(String) // For specific missing data like weight, height, DOB, sex
    case biologicalSexNotSet
    case healthKitStoreError(Error) // To wrap underlying HKError
    case unknownError(String) // General fallback

    var errorDescription: String? {
        switch self {
        case .invalidQuantityTypeIdentifier(let identifier):
            return "Invalid HealthKit quantity type identifier: \(identifier)."
        case .healthDataNotAvailable(let dataType):
            return "\(dataType) data is not available in HealthKit. Please ensure it's set in the Health app."
        case .biologicalSexNotSet:
            return "Biological sex is not set in HealthKit. This is required for some calculations."
        case .healthKitStoreError(let underlyingError):
            return "A HealthKit store error occurred: \(underlyingError.localizedDescription)"
        case .unknownError(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}

final class HealthKitManager: ObservableObject {
    @Published var authorizationError: String?
    @Published var dataInteractionError: String?

    private let healthStore = HKHealthStore()

    private var predicateForToday: NSPredicate {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start)
        return HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    }

    func requestAuthorizationAndLoadData() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKitManager",
                          code: HKError.Code.errorHealthDataUnavailable.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."])
        }

        guard let dietaryCaloriesEnergyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
              let activeEnergyBurnType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let heightType = HKQuantityType.quantityType(forIdentifier: .height),
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
              let birthdayType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
              let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
              let biologicalType = HKObjectType.characteristicType(forIdentifier: .biologicalSex) else {
            throw NSError(domain: "HealthKitManager",
                          code: HKError.Code.errorInvalidArgument.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid type read/write identifier(s)"])
        }

        let workoutType = HKObjectType.workoutType()
        let write: Set<HKSampleType> = [dietaryCaloriesEnergyType, activeEnergyBurnType, heightType, weightType]
        let read: Set<HKObjectType> = [dietaryCaloriesEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalType, bloodType, workoutType]

        try await healthStore.requestAuthorization(toShare: write, read: read)
    }

    func fetchMostRecentQuantitySample(for identifier: HKQuantityTypeIdentifier) async throws -> HKQuantity? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw NSError(domain: "HealthKitManager",
                          code: HKError.Code.errorInvalidArgument.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid quantity type identifier: \(identifier.rawValue)"])
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
}

// MARK: - ProfileViewModel
extension HealthKitManager {
    func fetchDateOfBirth() throws -> Date? {
        try healthStore.dateOfBirthComponents().date
    }

    func fetchBiologicalSex() throws -> HKBiologicalSex {
        try healthStore.biologicalSex().biologicalSex
    }

    func fetchBloodType() throws -> HKBloodType {
        try healthStore.bloodType().bloodType
    }

    func saveHeightInMeters(_ height: Double, date: Date = .now) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .height) else {
            throw NSError(domain: "HealthKitManager",
                          code: HKError.Code.errorInvalidArgument.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Height type not available for saving."])
        }
        let quantity = HKQuantity(unit: .meter(), doubleValue: height)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)

        try await saveSample(sample)
    }

    func saveWeightInKilograms(_ weight: Double, date: Date = .now) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw NSError(domain: "HealthKitManager",
                          code: HKError.errorInvalidArgument.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Weight type not available for saving."])
        }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weight)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)

        try await saveSample(sample)
    }

    private func saveSample(_ sample: HKSample) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            healthStore.save(sample) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume(returning: ())
                    return
                }

                continuation.resume(throwing: NSError(domain: "HealthKitManager",
                                                      code: HKError.Code.errorDatabaseInaccessible.rawValue,
                                                      userInfo: [NSLocalizedDescriptionKey: "Failed to save data"]))
            }
        }
    }
}

// MARK: - JournalViewModel
extension HealthKitManager {
    func fetchTodaysFoodCorrelations() async throws -> [HKCorrelation] {
        guard let foodCorrelationType = HKObjectType.correlationType(forIdentifier: .food) else {
            throw NSError(domain: "HealthKitManager",
                          code: HKError.Code.errorInvalidArgument.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to create food correlation type."])
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

                continuation.resume(returning: (samples as? [HKCorrelation]) ?? [])
            }
            self.healthStore.execute(query)
        }
    }

    func saveFoodCorrelation(name: String, joules: Double, date: Date = .now) async throws -> HKCorrelation {
        guard let foodCorrelationType = HKObjectType.correlationType(forIdentifier: .food),
              let energyConsumedType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            throw NSError(domain: "HealthKitManager",
                          code: HKError.Code.errorInvalidArgument.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to create required HealthKit types for saving food!"])
        }

        let energyQuantity = HKQuantity(unit: .joule(), doubleValue: joules)
        let energySample = HKQuantitySample(type: energyConsumedType, quantity: energyQuantity, start: date, end: date)
        let samples: Set<HKSample> = [energySample]

        let correlationMetadata: [String: Any] = [HKMetadataKeyFoodType: name]
        let correlation = HKCorrelation(type: foodCorrelationType, start: date, end: date, objects: samples, metadata: correlationMetadata)

        return try await withCheckedThrowingContinuation { continuation in
            healthStore.save(correlation) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume(returning: correlation)
                    return
                }

                continuation.resume(throwing: NSError(domain: "HealthKitManager",
                                                      code: HKError.Code.errorDatabaseInaccessible.rawValue,
                                                      userInfo: [NSLocalizedDescriptionKey: "Failed to save food correlation!"]))
            }
        }
    }
}

// MARK: - EnergyViewModel
extension HealthKitManager {
    struct BMRCalculationInputs {
        let weight: HKQuantity
        let height: HKQuantity
        let dateOfBirth: Date
        let sex: HKBiologicalSex
    }

    func fetchDailyTotal(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw NSError(domain: "HealthKitManager",
                          code: HKError.Code.errorInvalidArgument.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid quantity type identifier: \(identifier.rawValue)"])
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

    func fetchBMRCalculationInputs() async throws -> BMRCalculationInputs {
        let healthDataUnavailable = HKError.Code.errorHealthDataUnavailable.rawValue
        guard let weightQuantity = try await fetchMostRecentQuantitySample(for: .bodyMass) else {
            throw NSError(domain: "HealthKitManager", code: healthDataUnavailable, userInfo: [NSLocalizedDescriptionKey: "Weight data not available."])
        }
        guard let heightQuantity = try await fetchMostRecentQuantitySample(for: .height) else {
            throw NSError(domain: "HealthKitManager", code: healthDataUnavailable, userInfo: [NSLocalizedDescriptionKey: "Height data not available."])
        }
        guard let dob = try healthStore.dateOfBirthComponents().date else {
            throw NSError(domain: "HealthKitManager", code: healthDataUnavailable, userInfo: [NSLocalizedDescriptionKey: "Date of birth not available."])
        }

        let sex = try healthStore.biologicalSex().biologicalSex
        guard sex != .notSet else {
            throw NSError(domain: "HealthKitManager", code: healthDataUnavailable, userInfo: [NSLocalizedDescriptionKey: "Biological sex not set."])
        }

        return BMRCalculationInputs(
            weight: weightQuantity,
            height: heightQuantity,
            dateOfBirth: dob,
            sex: sex
        )
    }
}

// MARK: - Workouts
extension HealthKitManager {
    func fetchWorkouts(limit: Int = HKObjectQueryNoLimit) async throws -> [HKWorkout] {
        let type = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type,
                                      predicate: nil,
                                      limit: limit,
                                      sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            healthStore.execute(query)
        }
    }
}
