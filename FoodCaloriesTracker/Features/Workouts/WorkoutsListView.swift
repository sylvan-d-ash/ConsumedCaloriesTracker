//
//  WorkoutsListView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import SwiftUI

struct WorkoutsListView: View {
    @StateObject private var viewModel: ViewModel

    init(healthKitManager: HealthKitManager) {
        _viewModel = .init(wrappedValue: .init(healthKitManager: healthKitManager))
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    Section {
                        ProgressView("Loading workouts...")
                            .frame(maxWidth: .infinity)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if viewModel.workouts.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No workouts logged yet.",
                            systemImage: "figure.walk",
                            description: Text("Log your first workout to see it here!")
                        )
                    }
                } else {
                    Section("Recent Workouts") {
                        ForEach(viewModel.workouts) { item in
                            WorkoutRowView(item: item)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(
                                    EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
                                )
                        }
                    }
                }
            }
            .navigationTitle("Workouts")
            .onAppear {
                Task { await viewModel.fetchWorkouts() }
            }
            .refreshable {
                Task { await viewModel.fetchWorkouts() }
            }
        }
    }
}

#Preview {
    WorkoutsListView(healthKitManager: HealthKitManager())
}
