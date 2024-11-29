//
//  ActivityLevelSelectionCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-25.
//

import SwiftUI

struct ActivityLevelSelectionCell: View {
    let activityLevel: ActivityLevelSummary.ActivityLevel
    let isRecommended: Bool
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: activityLevel.systemImage)
                .foregroundStyle(.tint)
                .font(.largeTitle)
                .frame(width: 40)

            VStack(alignment: .leading) {
                HStack {
                    Text(activityLevel.name)

                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.caption2)
                            .foregroundStyle(.black)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.tint)
                            }
                    }
                }
                .fontDesign(.rounded)
                .bold()

                Text(activityLevel.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .selectable()
        .cardContainer(
            fill: isSelected ? AnyShapeStyle(.tint.tertiary) : AnyShapeStyle(.background.secondary),
            stroke: isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear)
        )
        .tint(activityLevel.barColor)
    }
}

#Preview {
    ScrollView {
        VStack {
            ForEach(ActivityLevelSummary.ActivityLevel.allCases) { activityLevel in
                ActivityLevelSelectionCell(
                    activityLevel: activityLevel,
                    isRecommended: activityLevel == .high,
                    isSelected: activityLevel == .intense
                )
            }
        }
        .padding()
    }
}
