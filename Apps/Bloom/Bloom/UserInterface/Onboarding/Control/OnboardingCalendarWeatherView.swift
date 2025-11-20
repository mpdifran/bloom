//
//  OnboardingCalendarWeatherView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-18.
//

import SwiftUI
import BloomUI
import AppUI
import BloomFoundation
import TelemetryDeck

struct OnboardingCalendarWeatherView: View {
  let onContinue: () -> Void

  init(onContinue: @escaping () -> Void) {
    self.onContinue = onContinue
  }

  @State private var index = 0
  @State private var didContinueToggle = false
  @State private var alertDetails: AlertDetails?

  @StateObject private var calendarManager = CalendarManager.shared
  @StateObject private var locationViewModel = LocationManagerViewModel.shared

  var body: some View {
    BloomScrollView {
      VStack {
        BudImage(.budCoach, dimension: 160)

        Text("What else would you like to share with me?")
          .font(.title)
          .bold()
          .fontDesign(.rounded)
          .horizontalAlignment(.leading)

        if index >= 1 {
          calendarSection
        }
        if index >= 2 {
          locationSection
        }
      }
      .padding(.top, 40)
    }
    .sensoryFeedback(.impact, trigger: didContinueToggle)
    .animation(.default, value: index)
    .alert(alertDetails: $alertDetails)
    .shelf {
      Button {
        didContinueToggle.toggle()
        onContinue()
      } label: {
        Text(continueButtonTitle)
          .horizontallyCentered()
      }
      .buttonStyle(.onboarding)
    }
    .task {
      await advanceIndex()
    }
    .onAppear {
      TelemetryDeck.signal("OB Other Permissions")
    }
  }
}

private extension OnboardingCalendarWeatherView {

  var continueButtonTitle: String {
    if calendarManager.authStatus == .notDetermined && locationViewModel.auth == .notDetermined {
      return "Skip"
    }
    return "Continue"
  }

  func advanceIndex() async {
    await Delay(500)
    index += 1
    await Delay(300)
    index += 1
  }
}

private extension OnboardingCalendarWeatherView {

  var calendarSection: some View {
    TodayCardCell(
      symbol: .calendar,
      title: "Calendar",
      content: "Share your calendar to see your events for the day, and get insights from Bud on how they affect your health!",
      color: .mutedRed
    ) {
      AsyncButton {
        await calendarManager.promptForPermission(alertDetails: $alertDetails)
      } label: {
        if calendarManager.authStatus == .fullAccess {
          Label("Access Granted", systemSymbol: .checkmark)
            .horizontallyCentered()
        } else {
          Text("Allow Access")
            .horizontallyCentered()
        }
      }
      .tint(.white)
      .buttonStyle(.primary)
      .colorScheme(.dark)
      .disabled(calendarManager.authStatus == .fullAccess)
    }
    .transition(.blurReplace)
  }

  var locationSection: some View {
    TodayCardCell(
      symbol: .locationFill,
      title: "Location",
      content: "Share your location to get weather forecasts alongside your health insights! Your precise location is never shared with Bud, only your current city.",
      color: .mutedBlue
    ) {
      AsyncButton {
        locationViewModel.promptForPermission(alertDetails: $alertDetails)
      } label: {
        if locationViewModel.auth.hasAccess {
          Label("Access Granted", systemSymbol: .checkmark)
            .horizontallyCentered()
        } else {
          Text("Allow Access")
            .horizontallyCentered()
        }
      }
      .tint(.white)
      .buttonStyle(.primary)
      .colorScheme(.dark)
      .disabled(locationViewModel.auth.hasAccess)
    }
    .transition(.blurReplace)
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingCalendarWeatherView() { }
  }
}
