//
//  LabelledMetric.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-06.
//

import SwiftUI

struct LabelledMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .bold()

            Text(value)
                .foregroundStyle(.tint)
                .bold()
                .font(.title3)
        }
    }
}

#Preview {
    LabelledMetric(label: "Protein", value: "34 Cal")
}
