//
//  SupplementBubble.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

struct SupplementBubble: View {
    let supplementReccomendation: SupplementReccomendationModel

    @State private var showPopover = false

    var body: some View {
        ChatBubble(
            position: .leading,
            showTail: true,
            shouldFill: true,
            foregroundStyle: Color(uiColor: .label),
            backgroundStyle: .chatGrey
        ) {
            HStack {
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        EfficacyView(efficacy: supplementReccomendation.efficacyRating)
                        Text(supplementReccomendation.supplementName)
                            .bold()
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(supplementReccomendation.recommendedDailyDose.capitalized)
                            .font(.caption)

                        Text("•")

                        Button("More Info") {
                            showPopover = true
                        }
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.accent)
                        .popover(isPresented: $showPopover) {
                            VStack(alignment: .leading) {
                                Text("More Info")
                                    .font(.caption)
                                    .bold()
                                Text(supplementReccomendation.shortText)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }

                Spacer()
            }
        }
    }
}

private extension SupplementBubble {

    var userAddedSupplement: Bool {
        false
    }
}

#Preview {
    SupplementBubble(
        supplementReccomendation: SupplementReccomendationModel(
            supplementName: "Melatonin",
            efficacyRating: 4,
            recommendedDailyDose: "2-3 mg",
            goal: "sleep",
            shortText: "It's great! It'll help you sleep better. Plus it has many other great benefits that I can't even list here."
        )
    )
}
