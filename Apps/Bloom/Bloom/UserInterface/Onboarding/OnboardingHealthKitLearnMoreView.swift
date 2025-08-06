//
//  OnboardingHealthKitLearnMoreView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-05.
//

import SwiftUI
import CoreHealth
import TelemetryDeck

struct OnboardingHealthKitLearnMoreView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 36) {
        titleSection
        healthDataUsageSection
        healthDataSecureSection
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
    VStack(spacing: 16) {
      Text("Health Data Usage")
        .font(.title2)

      Text("We ask for these permissions to provide you with the best experience possible.")
        .foregroundStyle(.secondary)
    }
  }

  var healthDataUsageSection: some View {
    VStack(alignment: .leading) {
      Text("Your health data is used for:")
        .font(.body)
        .fontWeight(.heavy)
        .fontDesign(.rounded)

      HealthDataUsageCell(
        title: "Chat with Bud",
        message: "Bud can give you personalized health advice based on your data."
      ) {
        Image(.budPeek)
          .resizable()
          .aspectRatio(contentMode: .fit)
      }

      HealthDataUsageCell(
        title: "Workouts",
        message: "Summarize and analyze your workouts."
      ) {
        Image(systemSymbol: .figureRun)
          .font(.title3)
      }

      HealthDataUsageCell(
        title: "Sleep",
        message: "Analyze your sleep patterns."
      ) {
        Image(systemSymbol: .moon)
      }

      HealthDataUsageCell(
        title: "Nutrition",
        message: "Track meals, calories, and macros."
      ) {
        Image(.nutritionTab)
      }

      HealthDataUsageCell(
        title: "Weight",
        message: "Track and manage your weight."
      ) {
        Image(.logWeightIcon)
      }
    }
  }

  var healthDataSecureSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Your health data stays secure:")
        .font(.body)
        .fontWeight(.heavy)
        .fontDesign(.rounded)

      Group {
        Text("• Only visible to you, on this device")
        Text("• Data shared with Bud stays anonymous")
        Text("• Permissions can be adjusted at any time")
        Text("• Health data is secured by \(Image(systemSymbol: .appleLogo)) Apple")
      }
      .foregroundStyle(.secondary)
    }
    .horizontalAlignment(.leading)
  }

  var privacyPolicyButton: some View {
    Link(destination: .privacyPolicy) {
      HStack {
        Text("Privacy Policy")
        Image(systemSymbol: .arrowUpForwardAppFill)
      }
    }
    .frame(height: 35)
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
