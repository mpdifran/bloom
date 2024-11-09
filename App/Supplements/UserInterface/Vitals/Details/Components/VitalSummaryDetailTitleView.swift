//
//  VitalSummaryDetailTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import SwiftUI

struct VitalSummaryDetailTitleView: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack {
            Text(title)
                .bold()
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        Text("Hello World")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VitalSummaryDetailTitleView(
                        title: "Exercise Effectiveness",
                        subtitle: "Last 30 Days"
                    )
                }
            }
    }
}
