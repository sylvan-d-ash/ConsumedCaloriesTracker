//
//  HealthAndFitnessApp.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

@main
struct HealthAndFitnessApp: App {
    @StateObject private var sharedHealthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView(healthKitManager: sharedHealthKitManager)
                .environmentObject(sharedHealthKitManager)
        }
    }
}
