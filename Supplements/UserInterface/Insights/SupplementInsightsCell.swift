//
//  SupplementInsightsCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct SupplementInsightsCell: View {
    let insights: SupplementInsights

    var body: some View {
        VStack(alignment: .leading) {
            Text("Supplement Recommendations")
                .multilineTextAlignment(.leading)
                .font(.title)
                .fontDesign(.rounded)
                .bold()

            Text(insights.shortText)

            ForEach(insights.recommendedSupplements, id: \.supplementName) { supp in
                Divider()
                RecommendedSupplementView(recommendedSupplement: supp)
            }
        }
    }
}

#Preview {
    List {
        SupplementInsightsCell(
            insights: .init(
                recommendedSupplements: [.init(
                    efficacyRating: 5,
                    goal: "sleep",
                    recommendedDailyDose: "5mg",
                    supplementName: "melatonin"
                )],
                shortText: "Given your goals and health info and current supplements here is a list of recommendations"
            )
        )
    }
}
