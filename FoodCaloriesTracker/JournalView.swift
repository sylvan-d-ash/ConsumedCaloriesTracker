//
//  JournalView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

struct JournalView: View {
    // To detect when app becomes active
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var viewModel: ViewModel

    init(healthKitManager: HealthKitManager) {
        _viewModel = .init(wrappedValue: ViewModel(healthKitManager: healthKitManager))
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello universe!")
            }
        }
    }
}
