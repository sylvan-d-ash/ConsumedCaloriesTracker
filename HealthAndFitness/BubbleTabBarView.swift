//
//  BubbleTabBarView.swift
//  HealthAndFitness
//
//  Created by Sylvan  on 17/06/2025.
//

import SwiftUI

public protocol BubbleTabRepresentable: Identifiable, Hashable {
    var iconName: String { get }
    var title: String { get }

    // The item itself will be its tag for type safety
    var tag: Self { get }
}

public struct BubbleTabBarView<Tab: BubbleTabRepresentable>: View {
    let tabs: [Tab]
    @Binding var selectedTab: Tab
    @State private var xAxis: CGFloat = 0

    // Keep namespace internal to this view
    @Namespace private var animation

    // Configuration properties
    let defaultIconColor: Color
    let selectedIconColor: Color
    let defaultTextColor: Color
    let selectedTextColor: Color
    let bubbleBackgroundColor: Color
    let barBackgroundColor: Color
    let shadowColor: Color

    private var bottomPadding: CGFloat {
        guard let padding = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.safeAreaInsets.bottom else { return 0 }
        return padding - 15
    }

    public init(
        tabs: [Tab],
        selectedTab: Binding<Tab>,
        defaultIconColor: Color = .gray,
        selectedIconColor: Color = .orange,
        defaultTextColor: Color = .gray,
        selectedTextColor: Color = .orange,
        bubbleBackgroundColor: Color = Color(UIColor.tertiarySystemBackground),
        barBackgroundColor: Color = Color(UIColor.tertiarySystemBackground),
        shadowColor: Color
    ) {
        self.tabs = tabs
        self._selectedTab = selectedTab
        self.defaultIconColor = defaultIconColor
        self.selectedIconColor = selectedIconColor
        self.defaultTextColor = defaultTextColor
        self.selectedTextColor = selectedTextColor
        self.bubbleBackgroundColor = bubbleBackgroundColor
        self.barBackgroundColor = barBackgroundColor
        self.shadowColor = shadowColor
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tabItem in
                // Adjust spacing between icon and text
                VStack(spacing: 0) {
                    GeometryReader { reader in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedTab = tabItem.tag
                                xAxis = reader.frame(in: .global).minX // midX??
                            }
                        }) {
                            Image(systemName: tabItem.iconName)
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundStyle(
                                    isSelected(tabItem) ? selectedIconColor : defaultIconColor
                                )
                                .padding(isSelected(tabItem) ? 15: 0)
                                .background(
                                    (isSelected(tabItem) ? bubbleBackgroundColor : Color.clear)
                                        .clipShape(.circle)
                                )
                                .matchedGeometryEffect(id: tabItem.tag, in: animation)
                                .offset(
                                    x: isSelected(tabItem) ? (reader.frame(in: .global).minX - reader.frame(in: .global).midX + (reader.size.width / 2) - 12.5) : 0,
                                    y: isSelected(tabItem) ? -45 : 0
                                )
                        }
                        .onAppear {
                            // Set initial xAxis if this tab is the first selected one
                            if isSelected(tabItem) {
                                // Small delay to ensure geometry is available
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                    guard reader.size.width > 0 else { return }
                                    xAxis = reader.frame(in: .global).minX
                                }
                            }
                        }
                    } // End GeometryReader
                    // For the icon button's tappable area and layout
                    .frame(width: 25, height: 30)

                    Text(tabItem.title)
                        .font(.caption)
                        .foregroundStyle(
                            isSelected(tabItem) ? selectedTextColor : defaultTextColor
                        )
                } // End VStack

                // Make each tab item take equal width
                if tabItem.tag != tabs.last?.tag {
                    Spacer(minLength: 0)
                }
            } // End ForEach
        } // End HStack
        .padding(.horizontal, 30)
        // Padding for the content inside the bar
        .padding(.vertical, 12)
        .background(
            barBackgroundColor
                .clipShape(BubbleTabBarCustomShape(xAxis: xAxis))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: shadowColor, radius: 8, x: 0, y: -4)
        )
        // Horizontal padding for the bar itself, relative to the screen edges
        .padding(.horizontal)
        // Bottom padding to account for safe area
        .padding(.bottom, bottomPadding)
    }

    private func isSelected(_ tab: Tab) -> Bool {
        tab.tag == selectedTab
    }
}

private struct BubbleTabBarCustomShape: Shape {
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
