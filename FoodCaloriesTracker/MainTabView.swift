//
//  MainTabView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        TabView {
            NavigationStack {
                ProfileView(healthKitManager: healthKitManager)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }

            NavigationStack {
                JournalView(healthKitManager: healthKitManager)
            }
            .tabItem {
                Label("Journal", systemImage: "book.closed")
            }

            NavigationStack {
                EnergyView()
            }
            .tabItem {
                Label("Energy", systemImage: "bolt.heart")
            }
        }
    }
}

#Preview("Default (Light)") {
    MainTabView()
        .environmentObject(HealthKitManager())
}

#Preview("Dark Mode") {
    MainTabView()
        .preferredColorScheme(.dark)
        .environmentObject(HealthKitManager())
}
