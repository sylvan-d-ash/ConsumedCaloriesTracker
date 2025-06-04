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
                }

                if let dataError = viewModel.dataInteractionError {
                    Section {
                        Text(dataError)
                            .foregroundStyle(
                                dataError.lowercased().contains("error") || dataError.lowercased().contains("invalid") ? .orange : .blue
                            )
                    }
                }

                Section("User Information") {
                    ForEach(viewModel.profileItems) { item in
                        HStack {
                            Text(item.unitLabel)

                            Spacer()

                            Text(item.value)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Your Profile")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
