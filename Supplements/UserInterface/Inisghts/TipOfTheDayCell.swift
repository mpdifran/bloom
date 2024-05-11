//
//  TipOfTheDayCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct TipOfTheDayCell: View {
    let tip: String

    var body: some View {
        Text(tip)
            .font(.title3)
            .fontDesign(.rounded)
            .bold()
    }
}

#Preview {
    List {
        TipOfTheDayCell(tip: "Eat better")
    }
}
