//
//  LogWorkoutView.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 06/06/2025.
//

import SwiftUI
import HealthKit

struct LogWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ViewModel
    private let onSuccessfulSave: (() -> Void)

    init(healthKitManager: HealthKitManager, onSuccessfulSave: @escaping (() -> Void)) {
        _viewModel = .init(wrappedValue: .init(healthKitManager: healthKitManager))
        self.onSuccessfulSave = onSuccessfulSave
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

                        TextField("0 kcal", value: $viewModel.activeEnergy, formatter: formatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    if viewModel.showDistanceField {
                        VStack(alignment: .leading) {
                            Text("Distance (\(viewModel.distanceUnitDisplay))")

                            HStack {
                                Picker("Distance Unit", selection: $viewModel.distanceUnit) {
                                    ForEach(viewModel.availableDistanceUnit, id: \.self) { unit in
                                        Text(unit.displayName)
                                            .tag(unit)
                                    }
                                }
                                .labelsHidden()

                                Spacer()

                                TextField("0 \(viewModel.distanceUnitDisplay)", value: $viewModel.distance, formatter: formatter)
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
            .alert("Workout Logged!", isPresented: $viewModel.successfullyAdded) {
                Button("OK") {
                    // NOTE: I don't like how this is done, but I'm tired,
                    // so I'll let it be for now
                    onSuccessfulSave()
                    dismiss()
                }
            }
        }
    }

    private var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 0 // Ensure non-negative
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

#Preview {
    LogWorkoutView(healthKitManager: HealthKitManager()) {}
}
