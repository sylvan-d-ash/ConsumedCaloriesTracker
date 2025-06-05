//
//  ProfileView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

private struct ProfileRowView: View {
    let item: ProfileItem
    var valueColor: Color = .secondary

    var body: some View {
        HStack {
            Text(item.unitLabel)

            Spacer()

            Text(item.value)
                .font(.subheadline)
                .foregroundStyle(valueColor)
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
                if let authMessage = viewModel.authorizationMessage {
                    Section {
                        Text(authMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let interactionMessage = viewModel.dataInteractionMessage {
                    Section {
                        Text(interactionMessage)
                            .font(.caption)
                            .foregroundStyle(determineMessageColor(for: interactionMessage))
                    }
                }

                Section("User Information") {
                    ForEach(viewModel.userInfoItems) { item in
                        ProfileRowView(item: item)
                    }
                }

                Section("Weight & Height") {
                    ForEach(viewModel.weightHeightItems) { item in
                        if item.type.isEditable {
                            Button {
                                viewModel.handleProfileItemSelection(item)
                            } label: {
                                ProfileRowView(item: item)
                                    .foregroundStyle(.primary)
                            }
                        } else {
                            ProfileRowView(item: item)
                        }
                    }
                }
            }
            .navigationTitle("Your Profile")
            .onAppear {
                viewModel.onViewAppear()
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showingInputAlert, presenting: viewModel.alertInputType) { _ in
                TextField(alertTextFieldPlaceholder(), text: $viewModel.alertInputValue)
                    .keyboardType(.decimalPad)

                Button("Save") {
                    viewModel.saveNewValue()
                }

                Button("Cancel", role: .cancel) {}
            } message: { type in
                Text(alertMessageText(for: type))
            }
        }
    }

    private func determineMessageColor(for message: String) -> Color {
        let lowercasedMessage = message.lowercased()
        if lowercasedMessage.contains("error") || lowercasedMessage.contains("invalid") || lowercasedMessage.contains("fail") {
            return .orange
        } else if lowercasedMessage.contains("success") {
            return .green
        }
        return .blue // Default for informational messages
    }

    private func alertTextFieldPlaceholder() -> String {
        guard let type = viewModel.alertInputType else { return "Enter new value" }
        switch type {
        case .height:
            return "Enter height in meters (e.g., 1.75)"
        case .weight:
            return "Enter weight in kilograms (e.g., 68.5)"
        default:
            return "Enter new value"
        }
    }

    private func alertMessageText(for itemType: ProfileItemType) -> String {
        switch itemType {
        case .height:
            return "Please enter your height in meters (m)."
        case .weight:
            return "Please enter your weight in kilograms (kg)."
        default:
            return "Enter the new value for \(itemType.rawValue.lowercased())."
        }
    }
}

#Preview {
    ProfileView(healthKitManager: HealthKitManager())
}
