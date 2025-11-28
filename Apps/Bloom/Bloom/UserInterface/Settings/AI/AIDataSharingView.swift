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
        healthDataSection
        otherDataSection
        linksSection
      }
      .groupedBackground()
      .navigationTitle("Personal Data Controls")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if showDismiss {
          ToolbarItem(placement: .cancellationAction) {
            DismissButton()
          }
        }
      }
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

  @ViewBuilder
  var explanationSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemSymbol: .heartTextClipboardFill)
          .foregroundStyle(.mutedRed, .fill.secondary)
          .font(.largeTitle)
        Text("Choose What You Want Bloom To Use")
      }
      .font(.title2)
      .bold()
      .fontDesign(.rounded)

      Text("I only send the data you enable for features like Today Insights, Chat with Bud, and Biological Age, and only when needed.")
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }

  @ViewBuilder
  var healthDataSection: some View {
    VStack {
      SectionTitleView("Health Data")
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

            CategoryToggleCell(
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

          CategoryToggleCell(
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
        openURL(.emailBloom(subject: "Bloom: AI Privacy Question"))
      } label: {
        Text("Questions?")
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

private struct CategoryToggleCell: View {
  let category: AIHealthCategory
  @Binding var isEnabled: Bool

  var body: some View {
    Toggle(isOn: $isEnabled) {
      HStack {
        RoundedRectangle(cornerRadius: 17)
          .fill(category.color)
          .frame(square: 45)
          .overlay {
            Image(systemSymbol: category.icon)
              .font(.title2)
              .foregroundStyle(.white)
          }

        VStack(alignment: .leading, spacing: 4) {
          Text(category.displayName)
            .font(.body)
            .fontDesign(.rounded)
            .bold()

          Text(category.description)
            .font(.body)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  PreviewEnvironment {
    AIDataSharingView()
  }
}
