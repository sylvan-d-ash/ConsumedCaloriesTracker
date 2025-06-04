//
//  ProfileView-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Foundation
import Combine

extension ProfileView {
    final class ViewModel: ObservableObject {
        @Published var profileItems = [ProfileItem]()
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
            profileItems = ProfileItem.example

            healthKitManager.$profileData
                .receive(on: DispatchQueue.main)
                .map { [weak self] dictionaryData -> [ProfileItem] in
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

        func handleProfileItemSelection(_ item: ProfileItem) {
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
            case .height:
                healthKitManager.saveHeight(value)
            case .weight:
                healthKitManager.saveWeight(value)
            default: break
            }
        }
    }
}
