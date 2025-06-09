//
//  EnergyView.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

private struct EnergyRowView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct EnergyView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var viewModel: ViewModel

    init(healthKitManager: HealthKitManager) {
        _viewModel = .init(wrappedValue: ViewModel(healthKitManager: healthKitManager))
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    Section {
                        ProgressView("Calculating Energy..")
                            .frame(maxWidth: .infinity)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Today's Energy Breakdown") {
                    EnergyRowView(title: "Resting Burn", value: viewModel.stringFromJoules(viewModel.restingEnergyBurnedJoules))
                    EnergyRowView(title: "Active Burn", value: viewModel.stringFromJoules(viewModel.activeEnergyBurnedJoules))
                    EnergyRowView(title: "Consumed", value: viewModel.stringFromJoules(viewModel.energyConsumedJoules))
                    EnergyRowView(title: "Net", value: viewModel.stringFromJoules(viewModel.netEnergyJoules))
                }
            }
            .navigationTitle("Energy")
            .onAppear {
                self.viewModel.refreshData()
            }
            .onChange(of: scenePhase) { _, newValue in
                if newValue == .active {
                    self.viewModel.refreshData()
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
        }
    }
}

#Preview {
    EnergyView(healthKitManager: HealthKitManager())
}
