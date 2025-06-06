//
//  WorkoutRowView.swift
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
