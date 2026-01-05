//
//  ExistingUserAIDataConsentView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-29.
//

import SwiftUI
import AppUI
import BloomUI
import CoreHealth
import SFSafeSymbols
import TelemetryDeck

struct ExistingUserAIDataConsentView: View {
  let onContinue: () -> Void

  @ObservedObject private var healthManager = HealthManager.shared
  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared
  @ObservedObject private var aiDataSharingSettings = AIDataSharingSettings.shared

  @State private var alertDetails: AlertDetails?
  @State private var isAISectionExpanded = false
  @State private var isHealthDataSectionExpanded = false
  @State private var isOtherDataSectionExpanded = false

  @Environment(\.openURL) private var openURL

  var body: some View {
    BloomScrollView(showsChatBar: false, padding: .bottom) {
      Image(.budFridge)
        .resizable()
        .scaledToFit()
        .parallaxOverscroll()

      VStack(alignment: .leading, spacing: 10) {
        explanationSection
        aiFeatureSection
        healthDataSection
        otherDataSection
        legalSection
      }
      .horizontalAlignment(.leading)
      .padding(.horizontal)
      .padding(.top)
    }
    .ignoresSafeArea(.all, edges: .top)
    .shelf {
      shelfContent
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .alert(alertDetails: $alertDetails)
    .onAppear {
      TelemetryDeck.signal("View ExistingUserAIDataConsentView")
    }
  }
}

private extension ExistingUserAIDataConsentView {

  @ViewBuilder
  var explanationSection: some View {
    Text("Your Data, Your Choice")
      .onboardingTextStyle()
    Text("To keep helping you with personalized health insights, and to provide personalized responses to your questions, I need your permission for a few things. You’re always in control of what you share.")
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
  var aiFeatureSection: some View {
    SectionTitleView("Bloom Plus")
      .padding(.horizontal)

    TodayInsightsPrivacyAIFeatureOptInCell(extraContext: "Bud will use the Personal Data Categories enabled below.")
      .cardContainer()

    ChatPrivacyAIFeatureOptInCell(extraContext: "Bud can reference the Personal Data Categories enabled below in chats.")
      .cardContainer()
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
        subtitle: "Personal Data Categories (such as sleep, physical activity, or nutrition) allow you to control what data is shared with the Bloom Plus features enabled above.",
        isExpanded: isHealthDataSectionExpanded,
        isEnabled: isHealthDataSectionEnabledBinding
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
        subtitle: "Other Data Categories (such as location, calendar, and weather) allow you to control what data is shared with the Bloom Plus features enabled above.",
        isExpanded: isOtherDataSectionExpanded,
        isEnabled: isOtherDataSectionEnabledBinding
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
    Text("You can change these settings anytime.")
      .font(.caption)
      .bold()
      .foregroundStyle(.secondary)
      .padding(.horizontal)

    AsyncButton {
      if aiDataSharingSettings.enabledCategories.isNotEmpty {
        if await !showConfirmationAlert() {
          return
        }
      }

      try await logConfirmation()
      onContinue()
    } label: {
      Text("Continue")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }
}

private extension ExistingUserAIDataConsentView {

  func showConfirmationAlert() async -> Bool {
    await withCheckedContinuation { continuation in
      alertDetails = AlertDetails(
        title: "Before You Continue",
        message: confirmationAlertBody,
        buttons: [
          AlertDetails.Button(title: "Edit Choices", role: .cancel, action: {
            continuation.resume(returning: false)
          }),
          AlertDetails.Button(title: "Agree", action: {
            continuation.resume(returning: true)
          })
        ]
      )
    }
  }

  var confirmationAlertBody: String {
    let numCategories = aiDataSharingSettings.enabledCategories.count
    let personalDataCategoriesText = numCategories == 1 ? "1 Personal Data category" : "\(numCategories) Personal Data categories"

    return "Bud will only use the \(personalDataCategoriesText) you turned on to generate personalized responses to your questions about health and wellness, and to generate personalized insights.\n\nDo you agree to Bud using the Personal Data categories you selected for these purposes?"
  }

  func logConfirmation() async throws {
    try await ConsentManager.shared.recordGranularConsent(externalHealthDataScreenVersion: "ExistingUserAIDataConsentView.v1")
  }
}

private extension ExistingUserAIDataConsentView {

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

  var isAISectionEnabledBinding: Binding<Bool> {
    Binding(
      get: {
        aiFeatureSettings.todayInsightsEnabled &&
        aiFeatureSettings.chatEnabled
      },
      set: { newValue in
        aiFeatureSettings.todayInsightsEnabled = newValue
        aiFeatureSettings.chatEnabled = newValue
      }
    )
  }

  var isHealthDataSectionEnabledBinding: Binding<Bool> {
    Binding(
      get: {
        let categoriesToCheck = AIHealthCategory.healthCategories.filter { category in
          category != .menstrualHealth || shouldShowMenstrualHealth
        }
        return categoriesToCheck.allSatisfy { aiDataSharingSettings.enabledCategories.contains($0) }
      },
      set: { newValue in
        let categoriesToModify = AIHealthCategory.healthCategories.filter { category in
          category != .menstrualHealth || shouldShowMenstrualHealth
        }
        if newValue {
          aiDataSharingSettings.enabledCategories.formUnion(categoriesToModify)
        } else {
          aiDataSharingSettings.enabledCategories.subtract(categoriesToModify)
        }
      }
    )
  }

  var isOtherDataSectionEnabledBinding: Binding<Bool> {
    Binding(
      get: {
        AIHealthCategory.otherCategories.allSatisfy { aiDataSharingSettings.enabledCategories.contains($0) }
      },
      set: { newValue in
        if newValue {
          aiDataSharingSettings.enabledCategories.formUnion(AIHealthCategory.otherCategories)
        } else {
          aiDataSharingSettings.enabledCategories.subtract(AIHealthCategory.otherCategories)
        }
      }
    )
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
    ExistingUserAIDataConsentView() { }
  }
}
