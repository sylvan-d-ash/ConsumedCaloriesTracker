//
//  WorkoutDetailsView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 06/06/2025.
//

import SwiftUI

struct WorkoutDetailsView: View {
    let item: WorkoutDisplayItem

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    HStack {
                        Text("Activity")
                        Spacer()
                        Text(item.name)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(item.dateRange)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(item.duration)
                            .foregroundColor(.secondary)
                    }
                    if let energy = item.energyBurned {
                        HStack {
                            Text("Active Kilocalories")
                            Spacer()
                            Text(energy)
                                .foregroundColor(.secondary)
                        }
                    }
                    if let distance = item.distance {
                        HStack {
                            Text("Distance")
                            Spacer()
                            Text(distance)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
//    // Very basic example
//    let mockEnergy = HKQuantity(unit: .kilocalorie(), doubleValue: 300)
//    let mockWorkout = HKWorkout(activityType: .running, start: Date().addingTimeInterval(-3600), end: Date(), duration: 3600, totalEnergyBurned: mockEnergy, totalDistance: nil, metadata: nil)
//    let mockDisplayItem = WorkoutDisplayItem(hkWorkout: mockWorkout)
    let item = WorkoutDisplayItem.createSampleWorkoutDisplayItems()[0]
    WorkoutDetailsView(item: item)
}
