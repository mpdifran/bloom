//
//  InsightTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import BloomModel
import TelemetryDeck
import BloomUI

struct InsightTodayCell: View {
  let insights: [TodayReportResponse.HealthInsight]
  let allowContextMenu: Bool

  init(
    insights: [TodayReportResponse.HealthInsight],
    allowContextMenu: Bool = true
  ) {
    self.insights = insights
    self.allowContextMenu = allowContextMenu
  }

  @State private var presentedSheet: AnyView?
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(insights, id: \.self) { insight in
          InsightCard(
            insight: insight,
            allowContextMenu: allowContextMenu,
            presentedSheet: $presentedSheet
          )
        }
      }
      .scrollTargetLayout()
      .padding(.horizontal)
    }
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
    .sheet($presentedSheet)
  }
}

struct InsightCard: View {
  let insight: TodayReportResponse.HealthInsight
  let allowContextMenu: Bool
  @Binding var presentedSheet: AnyView?
  
  @Environment(TabController.self) private var tabController: TabController
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(insight.title)
        .font(.headline)
        .fontDesign(.rounded)
        .bold()
        .lineLimit(2)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)

      Text(insight.body)
        .font(.body)
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)
      
      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .horizontalAlignment(.leading)
    .frame(width: 220)
    .cardContainer(fill: cardFill)
    .if(allowContextMenu) {
      $0.contextMenu {
        Button("Ask Bud", systemSymbol: .ellipsisMessage) {
          handleAskBudAction()
        }
      }
    }
  }
  
  var cardFill: AnyShapeStyle {
    if insight.priority < 4 {
      return AnyShapeStyle(LinearGradient(colors: [.mutedBlue, .mutedGreen], startPoint: .bottomLeading, endPoint: .topTrailing))
    } else if insight.priority < 8 {
      return AnyShapeStyle(LinearGradient(colors: [.mutedYellow, .mutedRed], startPoint: .bottom, endPoint: .topLeading))
    } else {
      return AnyShapeStyle(LinearGradient(colors: [.mutedPurple, .mutedPink], startPoint: .bottom, endPoint: .top))
    }
  }
  
  private func handleAskBudAction() {
    TelemetryDeck.signal("Ask Bud Attempted", parameters: ["source": "Today Insight"])
    
    EntitledAction(presentedSheet: $presentedSheet, focus: .todayInsights) {
      let context = ChatContext(title: insight.title, context: insight.body)
      tabController.chatContexts = [context]
      tabController.isShowingChat = true
      
      TelemetryDeck.signal("Ask Bud", parameters: ["source": "Today Insight"])
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView(padding: []) {
      InsightTodayCell(
        insights: [
          TodayReportResponse.HealthInsight(
            title: "Nutrition Consistency", 
            body: "Your protein intake has been steady this week, but consider adding more fiber-rich foods.",
            priority: 9
          ),
          TodayReportResponse.HealthInsight(
            title: "Hydration Goal",
            body: "You're 20% below your daily water intake target. Try to drink more water this afternoon.",
            priority: 7
          ),
          TodayReportResponse.HealthInsight(
            title: "Activity Recovery",
            body: "Yesterday's workout was intense with elevated heart rate zones. Consider light activity today for optimal recovery and muscle repair.",
            priority: 6
          ),
          TodayReportResponse.HealthInsight(
            title: "Great Sleep",
            body: "You got 8 hours of quality sleep last night.",
            priority: 2
          ),
        ]
      )
    }
  }
}
