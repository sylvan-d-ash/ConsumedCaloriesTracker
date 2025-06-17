//
//  MainTabView.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

private enum AppTab: String, CaseIterable, BubbleTabRepresentable {
    case profile, journal, energy, workouts

    var id: String { self.rawValue }

    var iconName: String {
        switch self {
        case .profile: return "person.crop.circle"
        case .journal: return "book.closed"
        case .energy: return "bolt.heart"
        case .workouts: return "figure.walk"
        }
    }

    var title: String {
        switch self {
        case .profile: return "Profile"
        case .journal: return "Journal"
        case .energy: return "Energy"
        case .workouts: return "Workouts"
        }
    }

    var tag: AppTab { self }
}

struct MainTabView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedAppTab: AppTab = .profile

    init(healthKitManager: HealthKitManager) {
        // Hide the system TabBar
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
            TabView(selection: $selectedAppTab) {
                ForEach(AppTab.allCases) { tab in
                    viewForTab(tab)
                }
            }

            BubbleTabBarView(
                tabs: AppTab.allCases,
                selectedTab: $selectedAppTab,
                shadowColor: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.1)
            )
        }
        // Ensure ZStack content can go to the very bottom
        .ignoresSafeArea(.all, edges: .bottom)
    }

    @ViewBuilder
    private func viewForTab(_ tab: AppTab) -> some View {
        switch tab {
        case .profile: ProfileView(healthKitManager: healthKitManager)
        case .journal: JournalView(healthKitManager: healthKitManager)
        case .energy: EnergyView(healthKitManager: healthKitManager)
        case .workouts: WorkoutsListView(healthKitManager: healthKitManager)
        }
    }
}

#Preview("Default (Light)") {
    let manager = HealthKitManager()
    MainTabView(healthKitManager: manager)
        .environmentObject(manager)
}

#Preview("Dark Mode") {
    let manager = HealthKitManager()
    MainTabView(healthKitManager: manager)
        .preferredColorScheme(.dark)
        .environmentObject(manager)
}
