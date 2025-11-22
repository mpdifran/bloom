//
//  OnboardingNotificationPermissionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI
import AppUI
import TelemetryDeck
import BloomFoundation
import BloomUI

struct OnboardingNotificationPermissionView: View {
  let onContinue: () -> Void

  @State private var isAuthorized = false
  @State private var index = 1
  @State private var notificationIndex = 0
  @State private var showContinueButton = false
  @State private var didContinue = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        BudImage(.budYoga)

        Group {
          Text("Let me keep you on track with helpful reminders and health insights.")
            .transition(.opacity)
            .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)
        }
        .onboardingTextStyle()

        MockHomeScreenView()
          .transition(.move(edge: .bottom))
          .appear(with: 2, currentIndex: index)
          .overlay {
            VStack {
              MockNotificationView(
                title: "Magnesium",
                message: "Don't forget to take your vitamins!",
                timestamp: "Now"
              )
              .transition(.move(edge: .top))
              .appear(with: 2, currentIndex: notificationIndex, secondaryIfNotCurrentIndex: false)

              MockNotificationView(
                title: "You met your steps goal!",
                message: "10,523 steps so far today.",
                timestamp: "5m ago"
              )
              .transition(.move(edge: .top))
              .appear(with: 1, currentIndex: notificationIndex, secondaryIfNotCurrentIndex: false)

              Spacer(minLength: 0)
            }
            .padding(24)
            .padding(.top, 46)
          }
          .horizontallyCentered()
      }
      .horizontalAlignment(.leading)
      .padding()
    }
    .groupedBackground()
    .animation(.bouncy, value: notificationIndex)
    .animation(.default, value: index)
    .animation(.default, value: isAuthorized)
    .animation(.default, value: showContinueButton)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.success, trigger: notificationIndex)
    .sensoryFeedback(.selection, trigger: didContinue)
    .task {
      while index < 2 {
        await advanceIndex()
      }

      await showNotifications()

      await Delay(800)

      withAnimation {
        showContinueButton = true
      }
    }
    .shelf(isVisible: showContinueButton) {
      if isAuthorized {
        Button {
          didContinue.toggle()
          onContinue()
        } label: {
          Text("Continue")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      } else {
        HStack {
          Button {
            didContinue.toggle()
            onContinue()
          } label: {
            Text("Skip")
              .horizontallyCentered()
          }
          .buttonStyle(.primaryAlternate)

          Button {
            NotificationManager.shared.requestAuthorization()
            isAuthorized = true
          } label: {
            Label("Enable", systemSymbol: .bellBadgeFill)
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
        }
      }
    }
    .onAppear {
      TelemetryDeck.signal("OB Notifications")
    }
  }
}

extension OnboardingNotificationPermissionView {

  func advanceIndex() async {
    await Delay(1000)

    index += 1
  }

  func showNotifications() async {
    while notificationIndex < 2 {
      await advanceNotificationIndex()
    }
  }

  func advanceNotificationIndex() async {
    await Delay(800)

    notificationIndex += 1
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingNotificationPermissionView { }
  }
}
