//
//  BloomTabView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SwiftUI

extension View {

  func tabBar() -> some View {
    self.modifier(TabBarViewModifier())
  }
}

struct TabBarViewModifier: ViewModifier {

  @Environment(TabController.self) private var tabController: TabController

  @State private var presentedSheet: AnyView?

  func body(content: Content) -> some View {
    content
      .safeAreaInset(edge: .bottom) {
        tabBar
      }
      .sheet($presentedSheet)
  }
}

extension TabBarViewModifier {

  var tabBar: some View {
    HStack {
      TabItem(title: "Today", image: .todayTab)
        .onTapGesture {
          tabController.activeTab = .today
        }
        .tint(tabController.activeTab == .today ? .primary : .secondary)

      TabItem(title: "Vitals", image: .vitalsTab)
        .onTapGesture {
          tabController.activeTab = .vitals
        }
        .tint(tabController.activeTab == .vitals ? .primary : .secondary)

      AddTabItem()
        .onTapGesture {
          presentedSheet = ActionsView().asAny
        }

      TabItem(title: "Nutrition", image: .nutritionTab)
        .onTapGesture {
          tabController.activeTab = .nutrition
        }
        .tint(tabController.activeTab == .nutrition ? .primary : .secondary)

      TabItem(title: "Profile", image: .profileTab)
        .onTapGesture {
          tabController.activeTab = .profile
        }
        .tint(tabController.activeTab == .profile ? .primary : .secondary)
    }
    .sensoryFeedback(.impact, trigger: tabController.activeTab)
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 40)
        .fill(.background)
        .ignoresSafeArea(edges: .bottom)
        .shadow(color: .text.opacity(0.1), radius: 20)
    }
  }
}

private struct TabItem: View {
  let title: String
  let image: ImageResource

  var body: some View {
    VStack(spacing: 3) {
      Image(image)
      Text(title)
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
    }
    .horizontallyCentered()
    .foregroundStyle(.tint)
    .selectable()
  }
}

private struct AddTabItem: View {

  var body: some View {
    Image(systemName: "plus")
      .foregroundStyle(.white)
      .font(.title3)
      .bold()
      .fontDesign(.rounded)
      .padding(10)
      .background {
        RoundedRectangle(cornerRadius: 18)
          .fill(
            LinearGradient(
              colors: [.mutedGreen, .mutedBlue],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
      }
      .horizontallyCentered()
  }
}
