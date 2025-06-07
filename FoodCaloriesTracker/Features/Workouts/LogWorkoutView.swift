//
//  LogWorkoutView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import SwiftUI
import HealthKit

struct LogWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ViewModel

    init(healthKitManager: HealthKitManager) {
        _viewModel = .init(wrappedValue: .init(healthKitManager: healthKitManager))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    Picker("Activity Type", selection: $viewModel.selectedActivityType) {
                        ForEach(viewModel.availableTypes) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }

                    DatePicker("Start Time", selection: $viewModel.startDate)

                    HStack {
                        Text("Duration (minutes)")

                        Spacer()

                        TextField("Minutes", value: $viewModel.durationMinutes, formatter: formatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Active Energy (kcal)")

                        Spacer()

                        TextField("kcal", text: $viewModel.activeEnergy)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    if viewModel.showDistanceField {
                        VStack(alignment: .leading) {
                            Text("Distance (\(viewModel.distanceUnitDisplay))")

                            HStack {
                                Spacer()

                                TextField(viewModel.distanceUnitDisplay, text: $viewModel.distance)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                    }
                }

                Section {
                    Button(action: {
                        Task { await viewModel.logWorkout() }
                    }) {
                        HStack {
                            Spacer()

                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Log Workout")
                            }

                            Spacer()
                        }
                    }
                    .foregroundStyle(.orange)
                    .disabled(viewModel.isLoading)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Log New Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 0 // Ensure non-negative
        return formatter
    }

}

#Preview {
    LogWorkoutView(healthKitManager: HealthKitManager())
}
