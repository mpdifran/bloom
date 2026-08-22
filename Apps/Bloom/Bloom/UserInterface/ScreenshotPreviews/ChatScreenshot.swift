//
//  ChatScreenshot.swift
//  Bloom
//

import SwiftUI
import AppUI
import BloomUI
import SFSafeSymbols

/// A chat with Bud, as it appears in the App Store screenshots.
///
/// `ChatBubbleCell` is the app's real bubble. The workout card and input bar are recomposed: the
/// real chat is a ChatLayout collection view driven by a live conversation, which a static preview
/// can't stand up.
struct ChatScreenshot: View {
  let fixtures: ScreenshotFixtures

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            ChatBubbleCell(
              message: fixtures.chatUserMessage,
              isDirect: false,
              isCurrentUser: true,
              showTail: true
            )

            Text(fixtures.chatBudReply)
              .font(.title3)
              .fontDesign(.rounded)
              .fixedSize(horizontal: false, vertical: true)

            workoutCard
          }
          .padding()
        }

        ChatBar(startFocused: true) { _, _ in }
      }
      .groupedBackground()
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button { } label: {
            Image(systemSymbol: .chevronLeft)
          }
          .buttonStyle(.plain)
          .bold()
        }

        ToolbarItem(placement: .principal) {
          HStack(spacing: 8) {
            BudImage(.budWorkout, dimension: 32)

            Text(fixtures.chatTitle)
              .font(.headline)
          }
        }
      }
    }
  }
}

private extension ChatScreenshot {

  var workoutCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Image(systemSymbol: .figureIndoorCycle)
          .font(.title)
          .foregroundStyle(.white)
          .frame(square: 56)
          .background(Circle().fill(.mutedGreen))

        VStack(alignment: .leading, spacing: 2) {
          Text(fixtures.chatWorkoutTitle)
            .font(.title3)
            .bold()
            .fontDesign(.rounded)

          Text(fixtures.chatWorkoutDetail)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 0)

        Image(systemSymbol: .chevronForward)
          .foregroundStyle(.tertiary)
      }

      Text(fixtures.chatWorkoutDescription)
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)

      Text(fixtures.chatWorkoutSaved)
        .font(.headline)
        .foregroundStyle(.secondary)
        .horizontallyCentered()
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.quaternary))
    }
    .cardContainer()
  }
}

#Preview("Chat with Bud") {
  ScreenshotPreviewHost(selectedTab: .today) { fixtures in
    ChatScreenshot(fixtures: fixtures)
  }
}
