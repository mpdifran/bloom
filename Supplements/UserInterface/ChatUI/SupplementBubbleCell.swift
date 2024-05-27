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

    @ObservedObject private var profileViewModel = ProfileViewModel.shared

    var body: some View {
        ChatBubble(position: .leading,
                   showTail: true,
                   shouldFill: true,
                   foregroundColor: Color(uiColor: .label),
                   backgroundColor: .chatGrey) {
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

                AddItemButton(hasAdded: userAddedSupplement) {
                    if userAddedSupplement {
                        profileViewModel.userSupplements.removeAll(where: { $0 ==  supplementReccomendation.supplementName})
                    } else {
                        profileViewModel.userSupplements.insert(supplementReccomendation.supplementName, at: 0)
                    }
                }
            }
        }
    }
}

private extension SupplementBubble {

    var userAddedSupplement: Bool {
        profileViewModel.userSupplements.contains(supplementReccomendation.supplementName)
    }
}

#Preview {
    SupplementBubble(
        supplementReccomendation: .init(
            supplementName: "Melatonin",
            efficacyRating: 4,
            recommendedDailyDose: "2-3 mg",
            goal: "sleep",
            shortText: "It's great! It'll help you sleep better. Plus it has many other great benefits that I can't even list here."
        )
    )
}
