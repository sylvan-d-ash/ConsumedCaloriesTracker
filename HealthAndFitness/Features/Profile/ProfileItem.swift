//
//  ProfileItem.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 04/06/2025.
//

import Foundation

enum ProfileItemType: String, CaseIterable, Identifiable {
    case age = "Age"
    case sex = "Biological Sex"
    case bloodType = "Blood Type"
    case height = "Height"
    case weight = "Weight"
    case bmi = "BMI"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .age: return NSLocalizedString("Age (yrs)", comment: "")
        case .sex: return NSLocalizedString("Biological Sex", comment: "")
        case .bloodType: return NSLocalizedString("Blood Type", comment: "")
        case .height: return NSLocalizedString("Height", comment: "")
        case .weight: return NSLocalizedString("Weight", comment: "")
        case .bmi: return NSLocalizedString("Body Mass Index (BMI)", comment: "")
        }
    }

    var isEditable: Bool {
        switch self {
        case .weight, .height: return true
        default: return false
        }
    }
}

struct ProfileItem: Identifiable {
    let type: ProfileItemType
    var unitLabel: String
    var value: String

    var id: String { type.id }

    init(type: ProfileItemType, value: String = NSLocalizedString("Not available", comment: "")) {
        self.type = type
        self.unitLabel = type.displayName
        self.value = value
    }

    static let example: [ProfileItem] = [
        ProfileItem(type: .age, value: "19"),
        ProfileItem(type: .height, value: "160"),
        ProfileItem(type: .weight, value: "60"),
        ProfileItem(type: .sex, value: "Female"),
        ProfileItem(type: .bloodType, value: "O+"),
        ProfileItem(type: .bmi, value: "25.5"),
    ]
}
