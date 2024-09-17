//
//  TargetVitalComponentView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import DataContainer

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

            Text(vital.status)
                .font(.headline)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(vital.color)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.trailing)
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
