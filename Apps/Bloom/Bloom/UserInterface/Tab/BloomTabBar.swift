//
//  BloomTabBar.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SFSafeSymbols
import SwiftUI

extension View {

  func tabBar() -> some View {
    self.modifier(TabBarViewModifier())
  }
}

struct TabBarViewModifier: ViewModifier {

  func body(content: Content) -> some View {
    content
      .safeAreaInset(edge: .bottom) {
        BloomTabBar()
      }
  }
}

struct BloomTabBar: View {

  @Environment(TabController.self) private var tabController: TabController

  @State private var logActionToggle = false
  @State private var presentedSheet: AnyView?

  var body: some View {
    HStack {
      TabItem(title: "Today", image: Image(.todayTab))
        .onTapGesture {
          tabController.activeTab = .today
        }
        .if(tabController.activeTab != .today) {
          $0.tint(.secondary)
        }

      TabItem(title: "Nutrition", image: Image(.nutritionTab))
        .onTapGesture {
          tabController.activeTab = .nutrition
        }
        .if(tabController.activeTab != .nutrition) {
          $0.tint(.secondary)
        }

      AddTabItem()
        .sensoryFeedback(.impact, trigger: logActionToggle)
        .onTapGesture {
          logActionToggle.toggle()
          presentedSheet = ActionsView().asAny
        }

      TabItem(title: "Vitals", image: Image(.vitalsTab))
        .onTapGesture {
          tabController.activeTab = .vitals
        }
        .if(tabController.activeTab != .vitals) {
          $0.tint(.secondary)
        }

      TabItem(title: "Workouts", image: Image(.workoutsTab))
        .onTapGesture {
          tabController.activeTab = .workouts
        }
        .if(tabController.activeTab != .workouts) {
          $0.tint(.secondary)
        }
    }
    .sheet($presentedSheet)
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
  let image: Image

  var body: some View {
    VStack(spacing: 3) {
      image
        .font(.system(size: 27))

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

  @Environment(ThemeController.self) private var themeController

  var body: some View {
    Image(systemSymbol: .plus)
      .foregroundStyle(.white)
      .font(.title3)
      .bold()
      .fontDesign(.rounded)
      .padding(10)
      .background {
        RoundedRectangle(cornerRadius: 18)
          .fill(
            LinearGradient(
              colors: [
                themeController.theme.color // TODO: Add more
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
      }
      .horizontallyCentered()
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      Spacer()
      Text("Hello World")
      Spacer()
    }
    .tabBar()
  }
}
