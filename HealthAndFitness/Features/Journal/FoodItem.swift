//
//  FoodItem.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import Foundation

struct FoodItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let joules: Double
}

extension FoodItem {
    static let example = FoodItem(name: "Wheat Bagel", joules: 240000.0)

    static let foodItems: [FoodItem] = [
        FoodItem(name: "Wheat Bagel", joules: 240000.0),
        FoodItem(name: "Bran with Raisins", joules: 190000.0),
        FoodItem(name: "Regular Instant Coffee", joules: 1000.0),
        FoodItem(name: "Banana", joules: 439320.0),
        FoodItem(name: "Cranberry Bagel", joules: 416000.0),
        FoodItem(name: "Oatmeal", joules: 150000.0),
        FoodItem(name: "Fruits Salad", joules: 60000.0),
        FoodItem(name: "Fried Sea Bass", joules: 200000.0),
        FoodItem(name: "Chips", joules: 190000.0),
        FoodItem(name: "Chicken Taco", joules: 170000.0)
    ]
}
