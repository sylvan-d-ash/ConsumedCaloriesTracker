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
    @State private var showingFoodPicker = false

    init(healthKitManager: HealthKitManager) {
        _viewModel = .init(wrappedValue: ViewModel(healthKitManager: healthKitManager))
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading && viewModel.loggedFoodItems.isEmpty {
                    ProgressView("Loading journal items...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                } else if viewModel.loggedFoodItems.isEmpty {
                    ContentUnavailableView(
                        "No food logged today",
                        systemImage: "fork.knife.circle",
                        description: Text("Tap the '+' button to add a food item.")
                    )
                } else {
                    List {
                        ForEach(viewModel.loggedFoodItems) { item in
                            HStack {
                                Text(item.name)

                                Spacer()

                                Text(ViewModel.energyFormatter.string(fromJoules: item.joules))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Food Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            showingFoodPicker = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFoodPicker) {
                FoodPickerView { item in
                    viewModel.foodItemSelectedFromPicker(item)
                }
            }
            .onAppear {
                viewModel.onAppear()
            }
            .onChange(of: scenePhase) { _, newValue in
                if newValue == .active {
                    viewModel.onBecameActive()
                }
            }
        }
    }
}

#Preview {
    JournalView(healthKitManager: HealthKitManager())
}
