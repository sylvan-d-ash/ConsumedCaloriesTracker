//
//  MainTabView.swift
//  FoodCaloriesTracker
//
//  Created by Sylvan  on 04/06/2025.
//

import SwiftUI

private struct TabItem: Identifiable {
    var id = UUID()
    var view: AnyView
    var icon: String
    var tag: String
    var name: String
}

private struct CustomShape: Shape {
    var xAxis: CGFloat

    // Animating Path
    var animatableData: CGFloat {
        get { xAxis }
        set { xAxis = newValue }
    }

    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))

            let center = xAxis

            path.move(to: CGPoint(x: center - 50, y: 0))

            let to1 = CGPoint(x: center, y: 35)
            let control1 = CGPoint(x: center - 25, y: 0)
            let control2 = CGPoint(x: center - 25, y: 35)

            let to2 = CGPoint(x: center + 50, y: 0)
            let control3 = CGPoint(x: center + 25, y: 35)
            let control4 = CGPoint(x: center + 25, y: 0)

            path.addCurve(to: to1, control1: control1, control2: control2)
            path.addCurve(to: to2, control1: control3, control2: control4)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedTabTag: String
    @State private var xAxis: CGFloat = 0
    @Namespace private var animation

    private var tabItems: [TabItem]

    init(healthKitManager: HealthKitManager) {
        self.tabItems = [
            TabItem(view: AnyView(ProfileView(healthKitManager: healthKitManager)),
                    icon: "person.crop.circle",
                    tag: "profile",
                    name: "Profile"),
            TabItem(view: AnyView(JournalView(healthKitManager: healthKitManager)),
                    icon: "book.closed",
                    tag: "journal",
                    name: "Journal"),
            TabItem(view: AnyView(EnergyView(healthKitManager: healthKitManager)),
                    icon: "bolt.heart",
                    tag: "energy",
                    name: "Energy"),
        ]

        _selectedTabTag = State(initialValue: self.tabItems.first?.tag ?? "profile")

        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
            TabView(selection: $selectedTabTag) {
                ForEach(tabItems) { item in
                    item.view
                        .tag(item.tag)
                }
            }

            HStack(spacing: 0) {
                ForEach(tabItems) { item in
                    GeometryReader { reader in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedTabTag = item.tag
                                xAxis = reader.frame(in: .global).minX
                            }
                        }) {
                            Image(systemName: item.icon)
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundStyle(selectedTabTag == item.tag ? .orange : .gray)
                                .padding(selectedTabTag == item.tag ? 15 : 0)
                                .background(
                                    (selectedTabTag == item.tag ? Color(UIColor.tertiarySystemBackground) : Color.clear)
                                        .clipShape(Circle())
                                )
                                .matchedGeometryEffect(id: item.tag, in: animation)
                                .offset(
                                    x: selectedTabTag == item.tag ? (reader.frame(in: .global).minX - reader.frame(in: .global).midX + (reader.size.width / 2) - 12.5) : 0, // Centering adjustment
                                    y: selectedTabTag == item.tag ? -50 : 0
                                )
                        }
                        .onAppear {
                            // Set initial xAxis for the first tab
                            if item.tag == tabItems.first?.tag {
                                // Small delay to ensure geometry is available
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                    xAxis = reader.frame(in: .global).minX
                                }
                            }
                        }
                    }
                    // This frame is for the GeometryReader's content (the button)
                    .frame(width: 25, height: 30)

                    if item.tag != tabItems.last?.tag {
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 30)
            // Vertical padding for the bar itself
            .padding(.vertical)
            .background(
                Color(UIColor.tertiarySystemBackground)
                    .clipShape(CustomShape(xAxis: xAxis))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.1), radius: 8, x: 0, y: -4)
            )
            // Padding for the bar within the screen
            .padding(.horizontal)
            // Adjust bottom padding to account for safe area
            .padding(
                .bottom,
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.safeAreaInsets.bottom ?? 0
            )
        }
        // Ensure ZStack content can go to the very bottom
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

#Preview("Default (Light)") {
    let manager = HealthKitManager()
    MainTabView(healthKitManager: manager)
        .environmentObject(manager)
}

#Preview("Dark Mode") {
    let manager = HealthKitManager()
    MainTabView(healthKitManager: manager)
        .preferredColorScheme(.dark)
        .environmentObject(manager)
}
