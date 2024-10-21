//
//  TodaysDateView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-19.
//

import SwiftUI

struct TodaysDateView: View {
    var body: some View {
        TimelineView(.everyMinute) { _ in
            HStack(spacing: 0) {
                VStack(alignment: .leading) {
                    Text("\(DateFormatter.justDayOfWeek.string(from: .now))")
                        .bold()
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                    Text("\(DateFormatter.justDateLong.string(from: .now))")
                        .font(.title2)
                        .fontDesign(.rounded)
                        .bold()
                }
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    TodaysDateView()
}
