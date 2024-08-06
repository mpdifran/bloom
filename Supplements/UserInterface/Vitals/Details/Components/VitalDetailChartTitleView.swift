//
//  VitalDetailChartTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-05.
//

import SwiftUI

struct VitalDetailChartTitleView: View {
    let title: String
    let valueLabel: String
    let value: String

    init(
        title: String,
        valueLabel: String = "AVG",
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

            Text(valueLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .bold()
                .fontDesign(.rounded)
        }
    }
}

#Preview {
    VitalDetailChartTitleView(title: "Net Energy", value: "500 Cals")
}
