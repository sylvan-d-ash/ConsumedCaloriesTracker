//
//  WorkoutsListView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import SwiftUI

struct WorkoutRowView: View {
    let item: WorkoutDisplayItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.caption)

                Text(item.duration)
                    .font(.headline)
                    .foregroundStyle(.orange)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(item.dateRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let energy = item.energyBurned {
                    Text(energy)
                        .font(.headline)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

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
