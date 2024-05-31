//
//  ChartTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI

struct ChartTitleView: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title3)
            .bold()
            .fontDesign(.rounded)
    }
}

#Preview {
    ChartTitleView("Sleep History")
}
