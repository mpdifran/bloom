//
//  SupplementInsightsSection.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct SupplementInsightsSection: View {
    let insights: SupplementInsights

    var body: some View {
        Section {
            Text(insights.shortText)

            ForEach(insights.recommendedSupplements, id: \.supplementName) { supp in
                RecommendedSupplementCell(recommendedSupplement: supp)
            }
        } header: {
            Text("Supplement Recommendations")
                .multilineTextAlignment(.leading)
                .font(.title2)
                .fontDesign(.rounded)
                .bold()
                .textCase(.none)
        }
    }
}

#Preview {
    List {
        SupplementInsightsSection(
            insights: .init(
                recommendedSupplements: [
                    .init(
                        supplementName: "Melatonin",
                        goal: "Sleep",
                        efficacyRating: 5,
                        recommendedDailyDose: "5 mg"
                    )
                ],
                shortText: "Given your goals and health info and current supplements here is a list of recommendations"
            )
        )
    }
}
