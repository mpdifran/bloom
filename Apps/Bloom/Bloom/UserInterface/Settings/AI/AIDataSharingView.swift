import SwiftUI
import BloomUI
import HealthKit
import CoreHealth

struct AIDataSharingView: View {

  let showDismiss: Bool

  init(showDismiss: Bool = false) {
    self.showDismiss = showDismiss
  }

  @ObservedObject private var settings = AIDataSharingSettings.shared
  @ObservedObject private var healthManager = HealthManager.shared

  @Environment(\.openURL) private var openURL

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        explanationSection
        turnOnAllButton
        healthDataSection
        otherDataSection
        linksSection
      }
      .groupedBackground()
      .navigationTitle("Data Shared with AI")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if showDismiss {
          ToolbarItem(placement: .cancellationAction) {
            DismissButton()
          }
        }
        ToolbarItem(placement: .primaryAction) {
          Button {
            openURL(.emailBloom(subject: "Bloom: AI Privacy Question"))
          } label: {
            Image(systemSymbol: .questionmark)
          }
          .buttonStyle(.plain)
        }
      }
      .animation(.default, value: settings.enabledCategories)
    }
  }
}

private extension AIDataSharingView {

  var shouldShowMenstrualHealth: Bool {
    switch healthManager.sex() {
    case .female, .other:
      true
    case .male, .notSet:
      false
    @unknown default:
      false
    }
  }

  var applicableCategories: [AIHealthCategory] {
    let healthCategories = AIHealthCategory.healthCategories.filter { category in
      // Filter out menstrual health for non-female users
      if category == .menstrualHealth && !shouldShowMenstrualHealth {
        return false
      }
      return true
    }
    return healthCategories + AIHealthCategory.otherCategories
  }

  var allCategoriesEnabled: Bool {
    let applicable = Set(applicableCategories)
    return applicable.isSubset(of: settings.enabledCategories)
  }

  var turnOnAllButton: some View {
    Button {
      if allCategoriesEnabled {
        // Turn off all
        applicableCategories.forEach { category in
          settings.enabledCategories.remove(category)
        }
      } else {
        // Turn on all
        applicableCategories.forEach { category in
          settings.enabledCategories.insert(category)
        }
      }
    } label: {
      Text(allCategoriesEnabled ? "Turn Off All" : "Turn On All")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }

  @ViewBuilder
  var explanationSection: some View {
    VStack(alignment: .leading) {
      DisplayAppIcon()
        .frame(square: 100)
        .horizontallyCentered()
        .padding(.bottom)

      Text("Choose What You Want Bloom To Use")
        .bold()

      Text("Only the data you enable is used for AI features like Today Insights, Chat with Bud, and Biological Age.")
        .foregroundStyle(.secondary)
    }
    .font(.title3)
    .fontDesign(.rounded)
    .horizontalAlignment(.leading)
    .padding(.bottom, 40)
  }

  @ViewBuilder
  var healthDataSection: some View {
    VStack {
      SectionTitleView("Personal Data")
        .padding(.horizontal)

      SettingsSectionContainer {
        ForEach(Array(AIHealthCategory.healthCategories.enumerated()), id: \.element) { index, category in
          // Skip menstrual health for non-female users
          if category == .menstrualHealth && !shouldShowMenstrualHealth {
            EmptyView()
          } else {
            if index > 0 && !(category == .menstrualHealth && !shouldShowMenstrualHealth) {
              // Only show divider if this isn't the first visible item
              if index == 0 || (index == 1 && AIHealthCategory.healthCategories[0] == .menstrualHealth && !shouldShowMenstrualHealth) {
                EmptyView()
              } else {
                Divider()
              }
            }

            HealthCategoryToggleCell(
              category: category,
              isEnabled: Binding(
                get: { settings.enabledCategories.contains(category) },
                set: { isEnabled in
                  if isEnabled {
                    settings.enabledCategories.insert(category)
                  } else {
                    settings.enabledCategories.remove(category)
                  }
                }
              )
            )
          }
        }
      }
    }
  }

  @ViewBuilder
  var otherDataSection: some View {
    VStack {
      SectionTitleView("Other Data")
        .padding(.horizontal)

      SettingsSectionContainer {
        ForEach(Array(AIHealthCategory.otherCategories.enumerated()), id: \.element) { index, category in
          if index > 0 {
            Divider()
          }

          HealthCategoryToggleCell(
            category: category,
            isEnabled: Binding(
              get: { settings.enabledCategories.contains(category) },
              set: { isEnabled in
                if isEnabled {
                  settings.enabledCategories.insert(category)
                } else {
                  settings.enabledCategories.remove(category)
                }
              }
            )
          )
        }
      }
    }
  }

  var linksSection: some View {
    HStack {
      Button {
        openURL(.termsOfService)
      } label: {
        Text("Terms of Service")
          .horizontallyCentered()
      }
      .buttonStyle(.primaryAlternate)

      Button {
        openURL(.privacyPolicy)
      } label: {
        Text("Privacy Policy")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .padding(.top)
    .padding(.top)
  }
}

#Preview {
  PreviewEnvironment {
    AIDataSharingView()
  }
}
