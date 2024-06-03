//
//  SleepProgramSectionHeader.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI

struct SleepProgramSectionHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.tint)
        }
        .zStackAlignment(.center)
    }
}

#Preview {
    List {
        SleepProgramSectionHeader(
            title: "Workouts",
            subtitle: "Last Two Weeks",
            systemImage: "figure.run"
        )
        .tint(.green)
    }
}
