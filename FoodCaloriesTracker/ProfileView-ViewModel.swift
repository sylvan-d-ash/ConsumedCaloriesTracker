//
//  ProfileView-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Foundation
import Combine

enum ProfileItemType: String, CaseIterable, Identifiable {
    case age = "Age"
    case height = "Height"
    case weight = "Weight"
    case sex = "Biological Sex"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .age: return NSLocalizedString("Age (yrs)", comment: "")
        case .height: return NSLocalizedString("Height", comment: "")
        case .weight: return NSLocalizedString("Weight", comment: "")
        case .sex: return NSLocalizedString("Biological Sex", comment: "")
        }
    }

    var isEditable: Bool {
        switch self {
        case .age, .sex: return false
        default: return true
        }
    }
}

struct ProfileItemData: Identifiable {
    let type: ProfileItemType
    var unitLabel: String
    var value: String

    var id: String { type.id }

    init(type: ProfileItemType, unitLabel: String? = nil, value: String = NSLocalizedString("Not available", comment: "")) {
        self.type = type
        self.unitLabel = unitLabel ?? type.displayName
        self.value = value
    }

    static let example: [ProfileItemData] = [
        ProfileItemData(type: .age, value: "19"),
        ProfileItemData(type: .height, value: "160"),
        ProfileItemData(type: .weight, value: "60"),
        ProfileItemData(type: .sex, value: "Female"),
    ]
}

extension ProfileView {
    final class ViewModel: ObservableObject {
        @Published var profileItems = [ProfileItemData]()
        @Published var authorizationError: String?
        @Published var dataInteractionError: String?

        @Published var showingInputAlert = false
        @Published var alertInputType: ProfileItemType?
        @Published var alertInputValue: String = ""

        private let healthKitManager = HealthKitManager()
        private var cancellables = Set<AnyCancellable>()
        private let itemsOrder: [ProfileItemType] = [.age, .sex, .height, .weight]

        var alertTitle: String {
            guard let type = alertInputType else { return "" }
            return "Update \(type.rawValue)"
        }

        init() {
            setupBindings()
        }

        private func setupBindings() {
            profileItems = ProfileItemData.example

            healthKitManager.$profileData
                .receive(on: DispatchQueue.main)
                .map { [weak self] dictionaryData -> [ProfileItemData] in
                    guard let `self` = self else { return [] }

                    return self.itemsOrder.compactMap { itemType in
                        dictionaryData[itemType]
                    }
                }
                .assign(to: &$profileItems)

            healthKitManager.$authorizationError
                .receive(on: DispatchQueue.main)
                .map { errorMessage -> String? in
                    guard let errorMessage else { return nil }
                    return "Authorization Error: \(errorMessage)"
                }
                .assign(to: &$authorizationError)

            // Subscribe to dataFetchError from HealthKitManager
            healthKitManager.$dataFetchError
                .receive(on: DispatchQueue.main)
                .map { errorMessage -> String? in
                    guard let errorMessage, !errorMessage.isEmpty else { return nil }
                    return "Data Error: \(errorMessage)"
                }
                .assign(to: &$dataInteractionError)
        }

        func onViewAppear() {
            healthKitManager.requestAuthorizationAndLoadData()
        }

        func handleProfileItemSelection(_ item: ProfileItemData) {
            guard item.type.isEditable else { return }
            alertInputType = item.type
            alertInputValue = ""
            showingInputAlert = true
        }

        func saveNewValue() {
            guard let type = alertInputType else { return }
            guard let value = Double(alertInputValue.replacingOccurrences(of: ",", with: ".")) else {
                dataInteractionError = "Invalid input: \(alertInputValue) is not a valid number"
                return
            }

            dataInteractionError = nil

            switch type {
            case .age, .sex: break
            case .height:
                healthKitManager.saveHeight(value)
            case .weight:
                healthKitManager.saveWeight(value)
            }
        }
    }
}
