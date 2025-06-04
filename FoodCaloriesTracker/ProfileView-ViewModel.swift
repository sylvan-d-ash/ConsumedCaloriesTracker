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
        @Published var userInfoItems: [ProfileItem] = []
        @Published var weightHeightItems: [ProfileItem] = []
        @Published var authorizationError: String?
        @Published var dataInteractionError: String?

        @Published var showingInputAlert = false
        @Published var alertInputType: ProfileItemType?
        @Published var alertInputValue: String = ""

        private let healthKitManager: HealthKitManager
        private var cancellables = Set<AnyCancellable>()
        private let userInfoItemOrder: [ProfileItemType] = [.age, .sex, .bloodType]
        private let weightHeightItemOrder: [ProfileItemType] = [.weight, .height, .bmi]

        var alertTitle: String {
            guard let type = alertInputType else { return "" }
            return "Update \(type.rawValue)"
        }

        init(healthKitManager: HealthKitManager) {
            self.healthKitManager = healthKitManager
            setupBindings()
        }

        private func setupBindings() {
            healthKitManager.$profileData
                .receive(on: DispatchQueue.main)
                .sink { [weak self] dictionaryData in
                    guard let `self` = self else { return }
                    self.userInfoItems = self.userInfoItemOrder.compactMap { dictionaryData[$0] }
                    self.weightHeightItems = self.weightHeightItemOrder.compactMap { dictionaryData[$0] }
                }
                .store(in: &cancellables)

            healthKitManager.$authorizationError
                .receive(on: DispatchQueue.main)
                .map { $0 != nil ? "Authorization Error: \($0!)" : nil }
                .assign(to: &$authorizationError)

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
