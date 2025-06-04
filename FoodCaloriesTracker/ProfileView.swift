//
//  ProfileView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let authorizationError = viewModel.authorizationError {
                    Section {
                        Text(authorizationError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else if let dataError = viewModel.dataInteractionError {
                    Section {
                        Text(dataError)
                            .foregroundStyle(
                                dataError.lowercased().contains("error") || dataError.lowercased().contains("invalid") ? .orange : .blue
                            )
                    }
                } else {
                    Section("User Information") {
                        ForEach(viewModel.profileItems) { item in
                            HStack {
                                Text(item.unitLabel)

                                Spacer()

                                Text(item.value)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.handleProfileItemSelection(item)
                            }
                            .disabled(item.type.isEditable == false)
                        }
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
    NavigationStack {
        ProfileView()
    }
}
