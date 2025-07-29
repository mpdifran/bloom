//
//  MorningReportInsightCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import SwiftUI
import TelemetryDeck

struct MorningReportInsightCell: View {
  let emoji: String
  let title: String
  let insight: String

  @Binding var rootPresentedSheet: AnyView?

  @Environment(TabController.self) private var tabController: TabController
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(title)
          .lineLimit(2)
        Spacer(minLength: 0)
        Text(emoji)
      }
      .font(.headline)
      .fontDesign(.rounded)
      .bold()
      .padding(.horizontal)
      .padding(.vertical, 12)
      .background {
        Rectangle()
          .fill(.background.secondary)
      }

      Text(insight)
        .font(.body)
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)
        .padding()

      AskBudButton {
        TelemetryDeck.signal(
          "Morning Report Insight Ask Bud Attempt"
        )

        EntitledAction(presentedSheet: $rootPresentedSheet) {
          dismiss()
          let context = ChatContext(title: title, context: insight)
          tabController.chatContexts = [context]
          tabController.isShowingChat = true

          TelemetryDeck.signal(
            "Morning Report Insight Ask Bud"
          )
        }
      }
      .padding(.horizontal, 8)
      .padding(.bottom, 8)
      .horizontallyCentered()
    }
    .cardContainer(includePadding: false)
  }
}

#Preview {
  @Previewable @State var presentedSheet: AnyView?

  PreviewEnvironment {
    BloomScrollView {
      MorningReportInsightCell(
        emoji: "🍕",
        title: "Too Much Za",
        insight: "You had way too much pizza yesterday. Try to not do that today bro.",
        rootPresentedSheet: $presentedSheet
      )

      MorningReportInsightCell(
        emoji: "🤯",
        title: "New Running Workout Record",
        insight: "You ran 14 km in one go! Way to go buddy! You're making great progress towards your goal.",
        rootPresentedSheet: $presentedSheet
      )
    }
    .sheet($presentedSheet)
  }
}
