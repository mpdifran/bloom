//
//  HeartRateVariabilityCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-21.
//

import SwiftUI

struct HeartRateVariabilityCell: View {

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .green)
                Text("Heart Rate Variability")
                    .fontDesign(.rounded)
                    .bold()

                Spacer()

                Text("35ms")
                    .font(.largeTitle)
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(.pink)
            }

            Text("Your heart rate variability is lower than average, take it easy today.")
        }
    }
}

#Preview {
    List {
        HeartRateVariabilityCell()
    }
}
