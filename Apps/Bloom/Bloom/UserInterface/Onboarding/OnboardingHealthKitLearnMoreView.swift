//
//  OnboardingHealthKitLearnMoreView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-05.
//

import SwiftUI
import CoreHealth
import TelemetryDeck
import BloomUI

struct OnboardingHealthKitLearnMoreView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 36) {
        titleSection
        healthDataUsageSection
        healthDataSecureSection
        disclaimerSection
        privacyPolicyButton
      }
      .padding()
      .padding(.top)
      .padding(.top)
      .font(.body)
      .bold()
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
      .fontDesign(.rounded)
    }
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .onAppear {
      TelemetryDeck.signal("OB HealthKit Learn More")
    }
  }
}

private extension OnboardingHealthKitLearnMoreView {

  @ViewBuilder
  var titleSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Why I need your Health data 💙")
        .font(.title2)

      Text("With your permission, I can use your Health data to give you better, more personal insights.")
        .foregroundStyle(.secondary)
    }
    .multilineTextAlignment(.leading)
  }

  var healthDataUsageSection: some View {
    VStack(alignment: .leading) {
      Text("Your health data is used for:")
        .font(.body)
        .fontWeight(.heavy)
        .fontDesign(.rounded)

      HealthDataUsageCell(
        title: "Chat with Bud",
        message: "Get personalized tips and advice based on your data."
      ) {
        Image(.budPeek)
          .resizable()
          .aspectRatio(contentMode: .fit)
      }

      HealthDataUsageCell(
        title: "Workouts",
        message: "Summarize and celebrate your workouts."
      ) {
        Image(systemSymbol: .figureRun)
          .font(.title3)
      }

      HealthDataUsageCell(
        title: "Sleep",
        message: "Spot patterns in your sleep to help you rest better."
      ) {
        Image(systemSymbol: .moon)
      }

      HealthDataUsageCell(
        title: "Nutrition",
        message: "Track meals, calories, and macros in one place."
      ) {
        Image(.nutritionTab)
      }

      HealthDataUsageCell(
        title: "Weight",
        message: "Follow your progress over time with friendly insights."
      ) {
        Image(.logWeightIcon)
      }
    }
  }

  var healthDataSecureSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Your data is always safe:")
        .font(.body)
        .fontWeight(.heavy)
        .fontDesign(.rounded)

      Group {
        Text("• Only visible to you, stored on your device")
        Text("• Shared with Bud anonymously and never tied to your identity")
        Text("• You can change permissions anytime in Settings")
        Text("• Secured by \(Image(systemSymbol: .appleLogo)) Apple")
      }
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.leading)
    }
    .horizontalAlignment(.leading)
  }

  var disclaimerSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Health information disclaimer:")
        .font(.body)
        .fontWeight(.heavy)
        .fontDesign(.rounded)

      Group {
        Text("Bloom uses Apple Health data together with AI to create general wellness insights. These insights are for educational purposes only and are not medical advice.\n\nAlways consult a qualified healthcare professional before making medical decisions.")
      }
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.leading)
    }
    .horizontalAlignment(.leading)
  }

  var privacyPolicyButton: some View {
    VStack(alignment: .leading) {
      Link(destination: .privacyPolicy) {
        HStack {
          Text("Privacy Policy")
          Image(systemSymbol: .arrowUpForwardAppFill)
        }
      }
      .frame(height: 35)

      Link(destination: .emailBloom(subject: "Health Data Questions")) {
        HStack {
          Text("Still have questions? Email us")
          Image(systemSymbol: .envelopeFill)
        }
      }
      .frame(height: 35)
    }
    .horizontalAlignment(.leading)
  }
}

struct HealthDataUsageCell<Content: View>: View {
  let title: String
  let message: String
  let icon: () -> Content

  init(
    title: String,
    message: String,
    @ViewBuilder icon: @escaping () -> Content
  ) {
    self.title = title
    self.message = message
    self.icon = icon
  }

  var body: some View {
    HStack {
      icon()
        .foregroundStyle(.tint)
        .frame(width: 40)

      VStack(alignment: .leading) {
        Text(title)
          .font(.headline)
          .bold()

        Text(message)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .multilineTextAlignment(.leading)

      Spacer(minLength: 0)
    }
    .cardContainer()
  }
}

#Preview {
  PreviewSheetPresent {
    OnboardingHealthKitLearnMoreView()
  }
}
