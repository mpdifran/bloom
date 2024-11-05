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
}

struct FocusAreaReviewRootView: View {
    @State private var step: Step = .vitalReview

    @State private var vitalModels = [VitalModel]()

    var body: some View {
        Group {
            switch step {
            case .vitalReview:
                FocusAreaVitalReviewView { vitalModels in
                    self.vitalModels = vitalModels
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
