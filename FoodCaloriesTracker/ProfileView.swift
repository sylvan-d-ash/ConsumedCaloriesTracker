//
//  ProfileView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

private struct ProfileRowView: View {
    let item: ProfileItem

    var body: some View {
        HStack {
            Text(item.unitLabel)

            Spacer()

            Text(item.value)
                .foregroundStyle(.secondary)
        }
    }
}

struct ProfileView: View {
    @StateObject private var viewModel: ViewModel

    init(healthKitManager: HealthKitManager) {
        _viewModel = .init(wrappedValue: ViewModel(healthKitManager: healthKitManager))
    }

    var body: some View {
        NavigationStack {
            List {
                if let authorizationError = viewModel.authorizationError {
                    Section {
                        Text(authorizationError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let dataError = viewModel.dataInteractionError {
                    Section {
                        Text(dataError)
                            .font(.caption)
                            .foregroundStyle(
                                dataError.lowercased().contains("error") || dataError.lowercased().contains("invalid") ? .orange : .blue
                            )
                    }
                }

                Section("User Information") {
                    ForEach(viewModel.userInfoItems) { item in
                        ProfileRowView(item: item)
                    }
                }

                Section("Weight & Height") {
                    ForEach(viewModel.weightHeightItems) { item in
                        ProfileRowView(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.handleProfileItemSelection(item)
                            }
                            .disabled(item.type.isEditable == false)
                    }
                }
            }
            .navigationTitle("Your Profile")
            .onAppear {
                viewModel.onViewAppear()
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showingInputAlert, presenting: viewModel.alertInputType) { _ in
                TextField("Enter new value", text: $viewModel.alertInputValue)
                    .keyboardType(.decimalPad)

                Button("Save") {
                    viewModel.saveNewValue()
                }

                Button("Cancel", role: .cancel) {}
            } message: { type in
                Text("Enter the new value for \(type.rawValue.lowercased())")
            }
        }
    }
}

#Preview {
    ProfileView(healthKitManager: HealthKitManager())
}
