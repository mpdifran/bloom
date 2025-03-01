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
  @State private var step: Step = .goalLookback

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      switch step {
      case .goalLookback:
        GoalLookbackView()
      case .proposeNewGoals:
        Text("TODO")
      }
    }
    .animation(.easeInOut(duration: 1), value: step)
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

#Preview {
  BaseReviewGoalsView()
}
