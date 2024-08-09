//
//  ActivityLevelDistributionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-09.
//

import SwiftUI

private extension CGFloat {
    static let spacing: CGFloat = 10
    static let barCornerRadius: CGFloat = 10
    static let maxBarWidthPercentage: CGFloat = 0.8
    static let barHeight: CGFloat = 30
}

struct ActivityLevelDistributionView: View {
    let ratioDistribution: [EnergyBurnedSummary.ActivityLevel : Int]

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: .spacing) {
                ForEach(EnergyBurnedSummary.ActivityLevel.allCases) { level in
                    ZStack {
                        RoundedRectangle(cornerRadius: .barCornerRadius)
                            .fill(.fill)
                            .frame(height: .barHeight)

                        RoundedRectangle(cornerRadius: .barCornerRadius)
                            .stroke(level.barColor, lineWidth: 2)
                            .frame(height: .barHeight)

                        RoundedRectangle(cornerRadius: .barCornerRadius)
                            .fill(level.barColor)
                            .frame(width: proxy.size.width * .maxBarWidthPercentage * CGFloat(ratioDistribution[level, default: 0]) / maxCount, height: .barHeight)
                            .zStackAlignment(.leading)

                        Text(level.name)
                            .font(.headline)
                            .bold()
                            .padding(.horizontal, 6)
                            .zStackAlignment(.leading)

                        RoundedRectangle(cornerRadius: .barCornerRadius)
                            .fill(.white)
                            .frame(width: proxy.size.width * .maxBarWidthPercentage * CGFloat(ratioDistribution[level, default: 0]) / maxCount, height: .barHeight)
                            .zStackAlignment(.leading)
                            .mask {
                                Text(level.name)
                                    .font(.headline)
                                    .bold()
                                    .padding(.horizontal, 6)
                                    .zStackAlignment(.leading)
                            }

                        Text(formattedPercent(for: level))
                            .font(.headline)
                            .bold()
                            .padding(.horizontal, 6)
                            .zStackAlignment(.trailing)
                    }
                }
            }
        }
        .frame(height: viewHeight)
    }
}

private extension ActivityLevelDistributionView {

    var viewHeight: CGFloat {
        CGFloat(EnergyBurnedSummary.ActivityLevel.allCases.count) * CGFloat.barHeight +
        CGFloat(EnergyBurnedSummary.ActivityLevel.allCases.count - 1) * CGFloat.spacing
    }

    var maxCount: CGFloat {
        CGFloat(ratioDistribution.values.max(keyPath: \.self) ?? 1)
    }

    var total: CGFloat {
        CGFloat(ratioDistribution.values.map({ Double($0) }).sum(keyPath: \.self))
    }

    func formattedPercent(for level: EnergyBurnedSummary.ActivityLevel) -> String {
        guard let count = ratioDistribution[level], count > 0 else { return "0%" }

        return String(format: "%.0f", CGFloat(count) / total * 100) + "%"
    }
}

#Preview {
    ScrollView {
        ActivityLevelDistributionView(
            ratioDistribution: [
                .sedentary : 10,
                .light: 13,
                .moderate: 4,
                .high: 1,
                .intense: 0
            ]
        )
        .cardContainer()
        .padding()
    }
    .groupedBackground()
}
