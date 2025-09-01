//
//  InsightTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import BloomModel
import TelemetryDeck

struct InsightTodayCell: View {
  let insights: [TodayReportResponse.HealthInsight]
  
  @State private var presentedSheet: AnyView?
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(insights, id: \.self) { insight in
          InsightCard(insight: insight, presentedSheet: $presentedSheet)
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

private struct InsightCard: View {
  let insight: TodayReportResponse.HealthInsight
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
    .contextMenu {
      Button("Ask Bud", systemSymbol: .ellipsisMessage) {
        handleAskBudAction()
      }
    }
  }
  
  var cardFill: AnyShapeStyle {
    if insight.priority < 4 {
      return AnyShapeStyle(LinearGradient(colors: [.mutedBlue, .mutedGreen], startPoint: .bottom, endPoint: .top))
    } else if insight.priority < 8 {
      return AnyShapeStyle(LinearGradient(colors: [.mutedYellow, .mutedRed], startPoint: .bottom, endPoint: .top))
    } else {
      return AnyShapeStyle(LinearGradient(colors: [.mutedPurple, .mutedPink], startPoint: .bottom, endPoint: .top))
    }
  }
  
  private func handleAskBudAction() {
    TelemetryDeck.signal("Today Insight Ask Bud Attempt")
    
    EntitledAction(presentedSheet: $presentedSheet) {
      let context = ChatContext(title: insight.title, context: insight.body)
      tabController.chatContexts = [context]
      tabController.isShowingChat = true
      
      TelemetryDeck.signal("Today Insight Ask Bud")
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
