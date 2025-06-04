//
//  MainTabView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
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

#Preview("Default (Light)") {
    MainTabView()
}

#Preview("Dark Mode") {
    MainTabView()
        .preferredColorScheme(.dark)
}
