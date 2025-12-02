//
//  PrivacyUnknownOptInView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-29.
//

import SwiftUI
import AppUI
import BloomUI
import CoreHealth

struct PrivacyUnknownOptInView: View {

  @ObservedObject private var healthManager = HealthManager.shared
  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared
  @ObservedObject private var aiDataSharingSettings = AIDataSharingSettings.shared

  @State private var isAISectionExpanded = false
  @State private var isAISectionEnabled = false

  @Environment(\.openURL) private var openURL

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      Image(.budFridge)
        .resizable()
        .scaledToFit()
        .parallaxOverscroll()

      VStack(alignment: .leading, spacing: 10) {
        explanationSection
        healthConsentSection
        aiFeatureSection
        healthDataSection
        otherDataSection
        legalSection
      }
      .horizontalAlignment(.leading)
      .padding(.horizontal)
      .padding(.top)
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .shelf {
      shelfContent
    }
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

private extension PrivacyUnknownOptInView {

  @ViewBuilder
  var explanationSection: some View {
    Text("Your Data, Your Choice")
      .onboardingTextStyle()
    Text("To keep helping you with personalized health insights, I need your permission for a few things. You’re always in control.")
      .secondaryOnboardingTextStyle()
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
  }

  @ViewBuilder
  var legalSection: some View {
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
  }

  @ViewBuilder
  var healthConsentSection: some View {
    VStack(alignment: .leading) {
      HStack {
        DisplayAppIcon(overrideAppIcon: .healthAppIcon)
          .frame(square: 30)
        Text("How Bloom Uses Your Data")
      }
      .font(.title3)
      .bold()
      .fontDesign(.rounded)

      Group {
        Text("Bloom reads your personal data from your device to let you set goals, view charts, and understand your progress.")
        Spacer()
        Text("Certain features (like Today Insights, Chat with Bud, or Biological Age) require sending only the data you choose to Bloom’s servers.")
      }
      .font(.subheadline)
      .bold()
      .fontDesign(.rounded)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }

  @ViewBuilder
  var aiFeatureSection: some View {
    SectionTitleView("Bloom Plus")
      .padding(.horizontal)

    DisclosureGroup(isExpanded: $isAISectionExpanded) {
      PrivacyAIFeatureOptInCell(
        title: "Today Insights",
        subtitle: "Personalized insights from your data.",
        isEnabled: $aiFeatureSettings.todayInsightsEnabled) {
          TodayInsightsIcon()
            .frame(width: 40)
        }
        .tint(.mutedOrange)

      Divider()

      PrivacyAIFeatureOptInCell(
        title: "Chat with Bud",
        subtitle: "Chat with Bud about your health and wellness.",
        isEnabled: $aiFeatureSettings.chatEnabled) {
          ChatWithBudIcon()
            .frame(width: 40)
        }
        .tint(.mutedLightBlue)

      Divider()

      PrivacyAIFeatureOptInCell(
        title: "Biological Age",
        subtitle: "Estimate your biological age based on your data.",
        isEnabled: $aiFeatureSettings.biologicalAgeEnabled) {
          BiologicalAgeIcon()
            .frame(width: 40)
        }
        .tint(.mutedGreen)
    } label: {
      HStack {
        VStack(alignment: .leading) {
          Text("Bloom Plus")

          Text("Enable AI powered features like Today Inisghts, Chat with Bud, and Biological Age.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        if !isAISectionExpanded {
          Toggle("", isOn: $isAISectionEnabled)
            .frame(maxWidth: 80)
            .tint(.mutedLightBlue)
        }
      }
      .font(.body)
      .bold()
      .fontDesign(.rounded)
    }
    .disclosureGroupStyle(
      PrivacySectionDisclosureGroupStyle(
        expandButtonTitle: "Choose Features Individually",
        isExpanded: $isAISectionExpanded
      )
    )
  }

  @ViewBuilder
  var healthDataSection: some View {
    SectionTitleView("Share Personal Data")
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
              get: { aiDataSharingSettings.enabledCategories.contains(category) },
              set: { isEnabled in
                if isEnabled {
                  aiDataSharingSettings.enabledCategories.insert(category)
                } else {
                  aiDataSharingSettings.enabledCategories.remove(category)
                }
              }
            )
          )
        }
      }
    }
  }

  @ViewBuilder
  var otherDataSection: some View {
    SectionTitleView("Share Other Data")
      .padding(.horizontal)

    SettingsSectionContainer {
      ForEach(Array(AIHealthCategory.otherCategories.enumerated()), id: \.element) { index, category in
        if index > 0 {
          Divider()
        }

        HealthCategoryToggleCell(
          category: category,
          isEnabled: Binding(
            get: { aiDataSharingSettings.enabledCategories.contains(category) },
            set: { isEnabled in
              if isEnabled {
                aiDataSharingSettings.enabledCategories.insert(category)
              } else {
                aiDataSharingSettings.enabledCategories.remove(category)
              }
            }
          )
        )
      }
    }
  }

  @ViewBuilder
  var shelfContent: some View {
    Text("I confirm I’m the age of majority where I live and consent to Bloom using my data as described above.")
      .font(.caption)
      .bold()
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.leading)
      .horizontalAlignment(.leading)
      .padding(.horizontal)

    AsyncButton {

    } label: {
      Text("Accept and Continue")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }
}

private extension PrivacyUnknownOptInView {

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
}

private struct PrivacyAIFeatureOptInCell<IconView: View>: View {

  let title: String
  let subtitle: String
  @Binding var isEnabled: Bool
  let iconBuilder: () -> IconView

  init(
    title: String,
    subtitle: String,
    isEnabled: Binding<Bool>,
    @ViewBuilder iconBuilder: @escaping () -> IconView
  ) {
    self.title = title
    self.subtitle = subtitle
    self._isEnabled = isEnabled
    self.iconBuilder = iconBuilder
  }

  var body: some View {
    Toggle(isOn: $isEnabled) {
      HStack {
        iconBuilder()
          .padding(.trailing, 8)

        VStack(alignment: .leading) {
          Text(title)
            .bold()
            .fontDesign(.rounded)
            .minimumScaleFactor(0.7)
            .lineLimit(2)

          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
      .padding(.vertical, 16)
      .frame(minHeight: 60)
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}

private struct PrivacySectionDisclosureGroupStyle: DisclosureGroupStyle {
  let expandButtonTitle: String
  @Binding var isExpanded: Bool

  func makeBody(configuration: Configuration) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      configuration.label

      Divider()

      if configuration.isExpanded {
        VStack(spacing: 0) {
          configuration.content
        }
        .padding(.vertical, -12)
      } else {
        Button {
          withAnimation(.easeInOut) {
            isExpanded.toggle()
          }
        } label: {
          Text(expandButtonTitle)
            .bold()
        }
      }
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    PrivacyUnknownOptInView()
  }
}
