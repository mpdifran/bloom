//
//  FocusAreaReviewRootView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-04.
//

import SwiftUI
import DataContainer

enum Step {
    case vitalReview
    case habitReview
}

struct FocusAreaReviewRootView: View {
    @State private var step: Step = .vitalReview
    @State private var vitalModels = [VitalModel]()

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch step {
            case .vitalReview:
                FocusAreaVitalReviewView { vitalModels in
                    self.vitalModels = vitalModels
                    self.step = .habitReview
                }
            case .habitReview:
                FocusAreaHabitReviewView(vitals: vitalModels) {
                    dismiss()
                }
            }
        }
        .animation(.easeInOut(duration: 1), value: step)
        .presentationCompactAdaptation(.fullScreenCover)
    }
}

#Preview {
    FocusAreaReviewRootView()
}
