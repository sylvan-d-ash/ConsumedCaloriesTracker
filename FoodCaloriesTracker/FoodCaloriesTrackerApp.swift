//
//  FoodCaloriesTrackerApp.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

@main
struct FoodCaloriesTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }

                NavigationStack {
                    JournalView()
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
}
