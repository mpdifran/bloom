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
import SFSafeSymbols

struct PrivacyUnknownOptInView: View {

  @ObservedObject private var healthManager = HealthManager.shared
  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared
  @ObservedObject private var aiDataSharingSettings = AIDataSharingSettings.shared

  @State private var isAISectionExpanded = false
  @State private var isAISectionEnabled = false
  @State private var isHealthDataSectionExpanded = false
  @State private var isHealthDataSectionEnabled = false
  @State private var isOtherDataSectionExpanded = false
  @State private var isOtherDataSectionEnabled = false

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
//    .removeScrollEdgeEffect(shouldHide: true)
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
        Text("Accessing Data on Device")
          .fixedSize(horizontal: false, vertical: true)
      }
      .font(.title3)
      .bold()
      .fontDesign(.rounded)

      Group {
        Text("Bloom reads your personal data from your device to let you set goals, view charts, and understand your progress.")
      }
      .font(.headline)
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
        subtitle: "Personalized daily insights from your data.",
        isEnabled: $aiFeatureSettings.todayInsightsEnabled) {
          TodayInsightsIcon()
            .frame(width: 40)
        }
        .tint(.mutedOrange)
        .padding(.vertical)

      Divider()

      PrivacyAIFeatureOptInCell(
        title: "Chat with Bud",
        subtitle: "Chat with Bud about your health and wellness.",
        isEnabled: $aiFeatureSettings.chatEnabled) {
          ChatWithBudIcon()
            .frame(width: 40)
        }
        .tint(.mutedLightBlue)
        .padding(.vertical)

      Divider()

      PrivacyAIFeatureOptInCell(
        title: "Biological Age",
        subtitle: "Estimate your biological age based on your data.",
        isEnabled: $aiFeatureSettings.biologicalAgeEnabled) {
          BiologicalAgeIcon()
            .frame(width: 40)
        }
        .tint(.mutedGreen)
        .padding(.vertical)
    } label: {
      DisclosureOverallToggleView(
        icon: .starFill,
        title: "Bloom Plus Features",
        subtitle: "Enable AI powered features like Today Inisghts, Chat with Bud, and Biological Age.",
        isExpanded: isAISectionExpanded,
        isEnabled: $isAISectionEnabled
      )
      .tint(.mutedYellow)
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
    SectionTitleView("Sharing Personal Data")
      .padding(.horizontal)

    DisclosureGroup(isExpanded: $isHealthDataSectionExpanded) {
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
    } label: {
      DisclosureOverallToggleView(
        icon: .heartFill,
        title: "Personal Data Categories",
        subtitle: "Personal Data Categories (such as sleep, physical activity, or nutrition) allow you to control what data is shared with our AI services.",
        isExpanded: isHealthDataSectionExpanded,
        isEnabled: $isHealthDataSectionEnabled
      )
      .tint(.mutedPink)
    }
    .disclosureGroupStyle(
      PrivacySectionDisclosureGroupStyle(
        expandButtonTitle: "Choose Categories Individually",
        isExpanded: $isHealthDataSectionExpanded
      )
    )
  }

  @ViewBuilder
  var otherDataSection: some View {
    SectionTitleView("Sharing Other Data")
      .padding(.horizontal)

    DisclosureGroup(isExpanded: $isOtherDataSectionExpanded) {
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
    } label: {
      DisclosureOverallToggleView(
        icon: .squareFillOnCircleFill,
        title: "Other Data Categories",
        subtitle: "Other Data Categories (such as location, calendar, and weather) allow you to control what data is shared with our AI services.",
        isExpanded: isOtherDataSectionExpanded,
        isEnabled: $isOtherDataSectionEnabled
      )
      .tint(.mutedIndigo)
    }
    .disclosureGroupStyle(
      PrivacySectionDisclosureGroupStyle(
        expandButtonTitle: "Choose Categories Individually",
        isExpanded: $isOtherDataSectionExpanded
      )
    )
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

private struct DisclosureOverallToggleView: View {
  let icon: SFSymbol
  let title: String
  let subtitle: String
  let isExpanded: Bool
  @Binding var isEnabled: Bool

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        HStack {
          RoundedRectangle(cornerRadius: 13)
            .fill(.tint)
            .frame(square: 44)
            .overlay {
              Image(systemSymbol: icon)
                .foregroundStyle(.white)
            }

          Text(title)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
        }

        Text(subtitle)
          .font(.headline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      if !isExpanded {
        Toggle("", isOn: $isEnabled)
          .frame(maxWidth: 80)
      }
    }
    .font(.title3)
    .bold()
    .fontDesign(.rounded)
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
