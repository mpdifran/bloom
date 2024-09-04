//
//  TargetVitalComponentView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

struct TargetVitalComponentView: View {
    let vital: VitalModel

    var body: some View {
        HStack {
            Image(systemName: vital.id.systemImage)
                .font(.title2)

            VStack(alignment: .leading) {
                Text("Focus")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(vital.id.name)
                    .bold()
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            HStack {
                Text(vital.status)
                    .font(.headline)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(vital.color)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.trailing)

                Group {
                    switch vital.trend {
                    case .increasing:
                        Image(systemName: "chevron.up.circle")
                    case .decreasing:
                        Image(systemName: "chevron.down.circle")
                    case .noTrend:
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.primary, .fill)
                    }
                }
                .foregroundStyle(.primary, vital.color)
                .font(.title)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
    }
}

#Preview {
    TargetVitalComponentView(
        vital: .init(
            id: .sleepQuality,
            subtitle: "15% Deep",
            status: "Good",
            score: 0.7,
            color: .green,
            trend: .increasing
        )
    )
}
