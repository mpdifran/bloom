//
//  LabelledMetricView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI

struct LabelledMetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(.tint)
        }
    }
}

#Preview {
    LabelledMetricView(label: "Move", value: "237/500 CAL")
}
