//
//  BodyWeightTodayWidgetView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-17.
//

import SwiftUI
import Charts
import HealthKit

struct BodyWeightTodayWidgetView: View {

    @State var viewModel = BodyWeightTodayWidgetView.ViewModel()

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text("Weight")
                    .font(.subheadline)
                    .bold()
                    .fontDesign(.rounded)

                Spacer()

                VStack(alignment: .trailing) {
                    Text(viewModel.latestWeight?.quantity.displayString(for: .pound(), formatter: .oneDecimalPlace) ?? "--")
                        .font(.title2)
                        .fontDesign(.rounded)
                        .bold()
                        .foregroundStyle(.tint)

                    Text(timestampString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Chart {
                ForEach(viewModel.lastMonthWeightSamples) { sample in
                    AreaMark(
                        x: .value("Date", sample.date),
                        yStart: .value("Weight", sample.quantity.localizedValue(for: .pound())),
                        yEnd: .value("", chartMin)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pastelIndigo.opacity(0.7), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", sample.date),
                        y: .value("Weight", sample.quantity.localizedValue(for: .pound()))
                    )

                    PointMark(
                        x: .value("Date", sample.date),
                        y: .value("Weight", sample.quantity.localizedValue(for: .pound()))
                    )
                }
            }
            .foregroundStyle(.tint)
            .chartYScale(domain: chartMin...chartMax, range: .plotDimension)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
        .cardContainer(fill: .background.secondary)
        .tint(.pastelIndigo)
    }
}

private extension BodyWeightTodayWidgetView {

    var timestampString: String {
        if let latestWeight = viewModel.latestWeight {
            return DateFormatter.relativeDateTimeShort.string(from: latestWeight.startDate)
        }
        return "Never"
    }

    var chartMin: Double {
        let defaultValue = HKQuantity(unit: .pound(), doubleValue: 100).localizedValue(for: .pound())
        return viewModel.lastMonthWeightSamples.min(by: {
            $0.quantity.localizedValue(for: .pound()) < $1.quantity.localizedValue(for: .pound())
        })?.quantity.localizedValue(for: .pound()) ?? defaultValue
    }

    var chartMax: Double {
        let defaultValue = HKQuantity(unit: .pound(), doubleValue: 250).localizedValue(for: .pound())
        return viewModel.lastMonthWeightSamples.max(by: {
            $0.quantity.localizedValue(for: .pound()) < $1.quantity.localizedValue(for: .pound())
        })?.quantity.localizedValue(for: .pound()) ?? defaultValue
    }
}

#Preview {
    ScrollView {
        VStack {
            BodyWeightTodayWidgetView()
        }
        .padding()
    }
    .groupedBackground()
}
