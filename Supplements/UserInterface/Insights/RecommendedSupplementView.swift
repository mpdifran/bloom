//
//  RecommendedSupplementView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct RecommendedSupplementView: View {
    let recommendedSupplement: RecommendedSupplement

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(recommendedSupplement.supplementName.capitalized)
                    .font(.title3)
                    .fontDesign(.rounded)
                    .bold()

                HStack {
                    Text(recommendedSupplement.recommendedDailyDose)
                    Text("•")
                    Text(recommendedSupplement.goal.capitalized)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            EfficacyView(efficacy: recommendedSupplement.efficacyRating)
        }
    }
}

#Preview {
    List {
        RecommendedSupplementView(
            recommendedSupplement: .init(
                efficacyRating: 5,
                goal: "sleep",
                recommendedDailyDose: "5mg",
                supplementName: "melatonin"
            )
        )
    }
}
