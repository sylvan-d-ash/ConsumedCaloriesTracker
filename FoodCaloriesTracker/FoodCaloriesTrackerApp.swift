//
//  FoodCaloriesTrackerApp.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

@main
struct FoodCaloriesTrackerApp: App {
    @StateObject private var sharedHealthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView(healthKitManager: sharedHealthKitManager)
                .environmentObject(sharedHealthKitManager)
        }
    }
}
