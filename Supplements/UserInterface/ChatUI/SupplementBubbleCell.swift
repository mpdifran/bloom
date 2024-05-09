//
//  SupplementBubble.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

struct SupplementBubble: View {
    let supplementReccomendation: SupplementReccomendationModel

    var body: some View {
        ChatBubble(position: .leading,
                   showTail: true,
                   shouldFill: true,
                   foregroundColor: Color(uiColor: .label),
                   backgroundColor: .chatGrey) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(supplementReccomendation.supplementName)
                            .bold()
                        Text(supplementReccomendation.recommendedDailyDose)
                            .font(.caption)

                    }

                    Spacer()

                    EfficacyView(efficacy: supplementReccomendation.efficacyRating)
                }
                Text(supplementReccomendation.shortText)
            }
        }
    }
}

#Preview {
    SupplementBubble(
        supplementReccomendation: .init(
            supplementName: "Melatonin",
            efficacyRating: 4,
            recommendedDailyDose: "2-3 mg",
            goal: "sleep",
            shortText: "It's great! It'll help you sleep better."
        )
    )
}
