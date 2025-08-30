//
//  InsightTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import BloomModel

struct InsightTodayCell: View {
  let insights: [TodayReportResponse.HealthInsight]
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(insights, id: \.self) { insight in
          InsightCard(insight: insight)
        }
      }
      .scrollTargetLayout()
      .padding(.horizontal)
    }
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
  }
}

private struct InsightCard: View {
  let insight: TodayReportResponse.HealthInsight
  
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
        .lineLimit(6)
      
      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .horizontalAlignment(.leading)
    .frame(width: 220)
    .cardContainer(fill: cardFill)
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
