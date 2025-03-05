//
//  BaseReviewGoalsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-28.
//

import SwiftUI

extension BaseReviewGoalsView {
  enum Step {
    case goalLookback
    case proposeNewGoals
  }
}

struct BaseReviewGoalsView: View {
  @State private var proposedGoalsResult: ProposedGoalsResult?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      if let result = proposedGoalsResult {
        ProposedNewGoalsView(proposedGoalsResult: result)
      } else {
        GoalLookbackView { proposedGoalsResult in
          withAnimation {
            self.proposedGoalsResult = proposedGoalsResult
          }
        }
      }
    }
    .animation(.easeInOut(duration: 1), value: proposedGoalsResult)
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

#Preview {
  BaseReviewGoalsView()
}
