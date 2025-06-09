//
//  WorkoutSummaryView.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 08/06/2025.
//

import SwiftUI
import HealthKit

private struct SummaryStatVew: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}


struct WorkoutSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    let workouts: [HKWorkout]

    private var summary: (count: Int, duration: TimeInterval, energy: Double) {
        let count = workouts.count
        let duration = workouts.reduce(0) { $0 + $1.duration }
        let energy = workouts.reduce(0.0) { $0 + ($1.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0) }
        return (count, duration, energy)
    }

    private var totalDuration: String {
        formatDuration(summary.duration)
    }

    var body: some View {
        if workouts.isEmpty {
            EmptyView()
        } else {
            HStack {
                SummaryStatVew(label: "Workouts", value: "\(summary.count)")

                Spacer()

                SummaryStatVew(label: "Total Time", value: totalDuration)

                Spacer()

                SummaryStatVew(label: "Total Energy", value: "\(Int(summary.energy))")
            }
            .padding(.vertical, 15)
            .background(Color(UIColor.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.05), radius: 3, x: 0, y: 2)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated // "1h 15m", "30m"
        return formatter.string(from: duration) ?? ""
    }
}
