//
//  ProfileView-ViewModel.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

enum ProfileItemType: String, CaseIterable, Identifiable {
    case age = "Age"
    case height = "Height"
    case weight = "Weight"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .age: return NSLocalizedString("Age (yrs)", comment: "")
        case .height: return NSLocalizedString("Height", comment: "")
        case .weight: return NSLocalizedString("Weight", comment: "")
        }
    }

    var isEditable: Bool {
        switch self {
        case .age: return false
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
    ]
}

extension ProfileView {
    final class ViewModel: ObservableObject {
        @Published var profileItems = [ProfileItemData]()
        @Published var authorizationError: String?
        @Published var dataInteractionError: String?

        init() {
            setupBindings()
        }

        func setupBindings() {
            profileItems = ProfileItemData.example
        }
    }
}
