//
//  VitalDetailChartTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-05.
//

import SwiftUI

struct VitalDetailChartTitleView: View {
    /// LocalizedStringKey, not String: a String literal is passed straight to Text without a
    /// catalog lookup, so every chart title rendered in English regardless of language.
    let title: LocalizedStringKey
    /// Stays String: callers pass already-localized values such as
    /// `StatTimePeriod.comparisonPeriodLabel`.
    let valueLabel: String
    let value: String

    init(
        title: LocalizedStringKey,
        valueLabel: String = String(localized: "AVG", comment: "Chart header label for an average value"),
        value: String
    ) {
        self.title = title
        self.valueLabel = valueLabel
        self.value = value
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .bold()
                .font(.title3)
                .fontDesign(.rounded)

            Spacer()

            if value.isNotEmpty {
                Text(valueLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .bold()
                .fontDesign(.rounded)
        }
    }
}

#Preview {
    VitalDetailChartTitleView(title: "Net Energy", value: "500 Cals")
}
