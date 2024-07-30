//
//  CorrelationChartCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-29.
//

import SwiftUI
import Charts

private extension Double {
    static let somewhatCorrelationThreshold: Double = 0.1
    static let correlationThreshold: Double = 0.35
}

extension CorrelationChartCell {
    struct DataSetConfig {
        let title: String
        let color: Color
        let unit: String
    }

    enum Correlation {
        case negativelyCorrelated
        case somewhatNegativelyCorrelated
        case notCorrelated
        case somewhatPositivelyCorrelated
        case positivelyCorrelated

        var name: String {
            switch self {
            case .negativelyCorrelated:
                "Negatively Correlated"
            case .somewhatNegativelyCorrelated:
                "Somewhat Negatively Correlated"
            case .notCorrelated:
                "Not Correlated"
            case .somewhatPositivelyCorrelated:
                "Somewhat Correlated"
            case .positivelyCorrelated:
                "Correlated"
            }
        }
    }
}

struct CorrelationChartCell: View {
    let title: String
    let dataSet: [DataPair]
    let correlationCoefficient: Double
    let aConfig: DataSetConfig
    let bConfig: DataSetConfig

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontDesign(.rounded)
                .bold()
            Text(correlation.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)

            chart
        }
    }
}

private extension CorrelationChartCell {

    var chart: some View {
        Chart {
            ForEach(dataSet) { dataPair in
                LineMark(
                    x: .value("Date", dataPair.date, unit: .day),
                    y: .value(aConfig.title, dataPair.a / aMax)
                )
                .foregroundStyle(by: .value("DataSet", aConfig.title))

                LineMark(
                    x: .value("Date", dataPair.date, unit: .day),
                    y: .value(bConfig.title, dataPair.b / bMax)
                )
                .foregroundStyle(by: .value("DataSet", bConfig.title))
            }
        }
        .chartForegroundStyleScale([
            aConfig.title : aConfig.color,
            bConfig.title : bConfig.color
        ])
        .frame(height: 160)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisTick()
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(doubleValue * aMax, specifier: "%.0f")\(aConfig.unit)")
                    }
                }
            }
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisTick()
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(doubleValue * bMax, specifier: "%.0f")\(bConfig.unit)")
                    }
                }
            }
        }
    }

    var aMax: Double {
        let collated = dataSet.collated(by: .weekOfYear)
        return collated.values.max(by: {
            $0.sum(keyPath: \.a) < $1.sum(keyPath: \.a)
        })?.sum(keyPath: \.a) ?? 1
    }

    var bMax: Double {
        let collated = dataSet.collated(by: .weekOfYear)
        return collated.values.max(by: {
            $0.sum(keyPath: \.b) < $1.sum(keyPath: \.b)
        })?.sum(keyPath: \.b) ?? 1
    }

    var correlation: Correlation {
        if correlationCoefficient < -.correlationThreshold {
            return .negativelyCorrelated
        } else if correlationCoefficient < -.somewhatCorrelationThreshold {
            return .somewhatNegativelyCorrelated
        } else if correlationCoefficient > .correlationThreshold {
            return .positivelyCorrelated
        } else if correlationCoefficient > .somewhatCorrelationThreshold {
            return .somewhatPositivelyCorrelated
        }
        return .notCorrelated
    }
}

#Preview {
    List {
        CorrelationChartCell(
            title: "Time in Daylight vs Sleep Length",
            dataSet: [
                .init(date: .now, a: 2.3, b: 7.3),
                .init(date: .now.addingTimeInterval(24 * 60 * 60), a: 3.1, b: 7.8),
                .init(date: .now.addingTimeInterval(24 * 60 * 60 * 2), a: 0.7, b: 6.9)
            ],
            correlationCoefficient: 0.4,
            aConfig: .init(title: "Time in Daylight", color: .orange, unit: "h"),
            bConfig: .init(title: "Sleep Length", color: .coreSleep, unit: "h")
        )
    }
}
