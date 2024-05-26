//
//  InsightSectionHeaderView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import SwiftUI

struct InsightSectionHeaderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .multilineTextAlignment(.leading)
            .font(.title2)
            .fontDesign(.rounded)
            .bold()
            .textCase(.none)
    }
}

#Preview {
    InsightSectionHeaderView(title: "Sleep Score")
}
