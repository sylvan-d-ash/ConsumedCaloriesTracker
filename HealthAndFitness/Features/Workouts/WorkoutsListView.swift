//
//  WorkoutsListView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import SwiftUI

struct WorkoutsListView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var viewModel: ViewModel
    @State private var showLogWorkoutView: Bool = false

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
                } else if viewModel.sectionHeaders.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No workouts logged yet.",
                            systemImage: "figure.walk",
                            description: Text("Tap the '+' button to log a workout.")
                        )
                    }
                } else {
                    WorkoutSummaryView(workouts: viewModel.fetchedWorkouts)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(
                            EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                        )

                    ForEach(viewModel.sectionHeaders, id: \.self) { section in
                        Section(viewModel.groupHeader(for: section)) {
                            if let workouts = viewModel.groupedWorkouts[section] {
                                ForEach(workouts) { item in
                                    ZStack {
                                        WorkoutRowView(item: item)
                                            .contentShape(Rectangle())

                                        NavigationLink(destination: WorkoutDetailsView(item: item)) {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(
                                        EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
                                    )
                                }
                            }
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log Workout", systemImage: "plus") {
                        showLogWorkoutView.toggle()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.orange)
                }
            }
            .sheet(isPresented: $showLogWorkoutView) {
                LogWorkoutView(healthKitManager: healthKitManager) {
                    Task { await viewModel.fetchWorkouts() }
                }
            }
        }
    }
}

#Preview {
    let healthKitManager = HealthKitManager()
    WorkoutsListView(healthKitManager: healthKitManager)
        .environmentObject(healthKitManager)
}
