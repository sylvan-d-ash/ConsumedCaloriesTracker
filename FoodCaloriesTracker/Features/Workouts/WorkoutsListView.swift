//
//  WorkoutsListView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import SwiftUI

struct WorkoutRowView: View {
    let item: WorkoutDisplayItem
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.green.opacity(colorScheme == .dark ? 0.3: 0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: item.iconName)
                    .font(.title2)
                    .foregroundStyle(.green)
                    .frame(width: 30)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.subheadline)

                Text(item.duration)
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(item.dateRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let energy = item.energyBurned {
                    Text(energy)
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.05), radius: 3, x: 0, y: 2)
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
//        .preferredColorScheme(.dark)
}
