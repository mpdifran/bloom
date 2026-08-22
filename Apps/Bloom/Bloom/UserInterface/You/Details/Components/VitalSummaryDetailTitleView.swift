//
//  VitalSummaryDetailTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import SwiftUI

struct VitalSummaryDetailTitleView: View {
    /// LocalizedStringKey, not String: a String literal is passed straight to Text without a
    /// catalog lookup, so every detail screen title rendered in English regardless of language.
    let title: LocalizedStringKey
    /// Stays String: callers pass already-localized values such as `StatTimePeriod.displayName`.
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
