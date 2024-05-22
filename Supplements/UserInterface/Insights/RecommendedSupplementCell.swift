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

            Button(action: {
                guard !userAddedSupplement else { return }

                profileViewModel.userSupplements.insert(recommendedSupplement.supplementName, at: 0)
                feedbackGenerator.impactOccurred()
            }, label: {
                Image(systemName: userAddedSupplement ? "checkmark.circle.fill" : "plus.circle.fill")
                    .foregroundStyle(.white, .tint)
                    .font(.largeTitle)
                    .fontDesign(.rounded)
                    .contentTransition(.symbolEffect)
            })
        }
        .animation(.bouncy, value: profileViewModel.userSupplements.count)
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

private extension RecommendedSupplementCell {

    var userAddedSupplement: Bool {
        profileViewModel.userSupplements.contains { supplement in
            supplement.localizedCaseInsensitiveContains(recommendedSupplement.supplementName) ||
            recommendedSupplement.supplementName.localizedCaseInsensitiveContains(supplement)
        }
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
