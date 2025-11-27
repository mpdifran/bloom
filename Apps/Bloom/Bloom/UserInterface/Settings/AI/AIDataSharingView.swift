import SwiftUI
import BloomUI
import HealthKit
import CoreHealth

struct AIDataSharingView: View {
  @AIDataSharingSettingsStorage("AIDataSharing.settings") private var settings = AIDataSharingSettings()
  @ObservedObject private var healthManager = HealthManager.shared

  private var shouldShowMenstrualHealth: Bool {
    switch healthManager.sex() {
    case .female, .other:
      true
    case .male, .notSet:
      false
    @unknown default:
      false
    }
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
          explanationSection
          healthDataSection
          otherDataSection
      }
      .groupedBackground()
      .navigationTitle("Personal Data Controls")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
  }

  @ViewBuilder
  private var explanationSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Control What's Shared")
        .font(.title2)
        .bold()
        .fontDesign(.rounded)

      Text("Control what health data is shared with AI-powered features like Today Insights, Chat with Bud, and Biological Age calculations.")
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }

  @ViewBuilder
  private var healthDataSection: some View {
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
  private var otherDataSection: some View {
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
}

private struct CategoryToggleCell: View {
  let category: AIHealthCategory
  @Binding var isEnabled: Bool

  var body: some View {
    Toggle(isOn: $isEnabled) {
      HStack {
        RoundedRectangle(cornerRadius: 17)
          .fill(.tint)
          .frame(square: 45)
          .overlay {
            Image(systemName: category.icon)
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
