//
//  LabelledMetric.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-06.
//

import SwiftUI

struct LabelledMetric: View {
    /// LocalizedStringKey, not String: a String literal is passed straight to Text without a
    /// catalog lookup, so the label rendered in English regardless of language.
    let label: LocalizedStringKey
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
