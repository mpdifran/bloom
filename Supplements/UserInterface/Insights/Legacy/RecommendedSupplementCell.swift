//
//  RecommendedSupplementCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct RecommendedSupplementCell: View {
    let recommendedSupplement: RecommendedSupplement

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    @ObservedObject private var profileViewModel = ProfileViewModel.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    EfficacyView(efficacy: recommendedSupplement.efficacyRating)
                    Text(recommendedSupplement.supplementName)
                        .font(.title3)
                        .fontDesign(.rounded)
                        .bold()
                }

                VStack(alignment: .leading) {
                    Text(recommendedSupplement.goal)
                        .font(.subheadline)
                    Text(recommendedSupplement.recommendedDailyDose)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            AddItemButton(hasAdded: userAddedSupplement) {
                if userAddedSupplement {
                    profileViewModel.userSupplements.removeAll { $0 == recommendedSupplement.supplementName }
                } else {
                    profileViewModel.userSupplements.insert(recommendedSupplement.supplementName, at: 0)
                }
            }
        }
        .animation(.bouncy, value: profileViewModel.userSupplements.count)
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

private extension RecommendedSupplementCell {

    var userAddedSupplement: Bool {
        profileViewModel.userSupplements.contains(recommendedSupplement.supplementName)
    }
}

#Preview {
    List {
        RecommendedSupplementCell(
            recommendedSupplement: .init(
                supplementName: "Melatonin",
                goal: "Sleep",
                efficacyRating: 5,
                recommendedDailyDose: "5 mg"
            )
        )
    }
}
