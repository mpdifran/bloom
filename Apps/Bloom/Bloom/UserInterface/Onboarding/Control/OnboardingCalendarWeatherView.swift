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
        BudImage(.budBicycle, dimension: 160)

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
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.impact, trigger: didContinueToggle)
    .alert(alertDetails: $alertDetails)
    .shelf {
      Button {
        didContinueToggle.toggle()
        onContinue()
      } label: {
        Text("Continue")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .task {
      await advanceIndex()
    }
    .onAppear {
      TelemetryDeck.signal("OB Other Permissions")
      calendarManager.checkPermission()
    }
  }
}

private extension OnboardingCalendarWeatherView {

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
      content: "See your schedule for the day, and help Bud keep your goals aligned with your routine.",
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
      content: "Share your location to get weather forecasts alongside your health insights. Bloom only uses your city-level location, never your precise location.",
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
