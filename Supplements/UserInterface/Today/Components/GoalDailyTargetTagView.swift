//
//  GoalDailyTargetTagView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-04.
//

import SwiftUI

struct GoalDailyTargetTagView: View {
    let formattedTarget: String

    var body: some View {
        HStack {
            Image(systemName: "trophy")
                .foregroundStyle(.tint)

            VStack(alignment: .leading) {
                Text(formattedTarget)
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(.tint)
                Text("per day")
                    .font(.caption2)
//                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.fill)
        }
    }
}

#Preview {
    GoalDailyTargetTagView(formattedTarget: "2 km")
}
