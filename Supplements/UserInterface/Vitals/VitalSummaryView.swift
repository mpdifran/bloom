//
//  VitalSummaryView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-23.
//

import SwiftUI

struct VitalSummaryView: View {
    let hrvStatus: VitalStatusData?
    let sleepStatus: VitalStatusData?
    let rhrStatus: VitalStatusData?

    var body: some View {
        VStack {
            DailyVitalMeterView(meterValue: meterScore)

            HStack(alignment: .top) {
                Spacer()
                if let hrvStatus {
                    VitalDetailCardView(statusData: hrvStatus)
                    Spacer()
                }
                if let sleepStatus {
                    VitalDetailCardView(statusData: sleepStatus)
                    Spacer()
                }
                if let rhrStatus {
                    VitalDetailCardView(statusData: rhrStatus)
                    Spacer()
                }
            }
        }
    }
}

extension VitalSummaryView {

    private var meterScore: CGFloat {
        [hrvStatus, sleepStatus, rhrStatus].compactMap({ $0?.score }).average(keyPath: \.self)
    }
}

struct VitalDetailCardView: View {
    let statusData: VitalStatusData

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.background)
            .overlay {
                VStack {
                    Group {
                        Image(systemName: statusData.mode.systemImage)
                            .foregroundStyle(.white, statusData.mode.color)
                        Text(statusData.value)
                    }
                    .foregroundStyle(statusData.mode.color)

                    Spacer()

                    Text(statusData.name)
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.title3)
                .bold()
                .fontDesign(.rounded)
                .padding()
            }
            .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    VitalSummaryView(
        hrvStatus: .init(
            name: "Heart Rate Variability",
            value: "39 ms",
            mode: .warning,
            score: 0.3
        ),
        sleepStatus: .init(
            name: "Sleep Quality",
            value: "Great",
            mode: .excel,
            score: 0.9
        ),
        rhrStatus: .init(
            name: "Resting Heart Rate",
            value: "59 bpm",
            mode: .good,
            score: 0.6
        )
    )
}
