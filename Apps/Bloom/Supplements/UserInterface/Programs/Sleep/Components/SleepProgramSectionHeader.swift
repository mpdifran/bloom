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
    let isMulticolored: Bool

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        isMulticolored: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.isMulticolored = isMulticolored
    }

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
                .if(isMulticolored) {
                    $0.foregroundStyle(.white, .tint)
                }
                .if(!isMulticolored) {
                    $0.foregroundStyle(.tint)
                }

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

        SleepProgramSectionHeader(
            title: "Resting Heart Rate",
            subtitle: "Last Two Weeks",
            systemImage: "arrow.down.heart.fill",
            isMulticolored: true
        )
        .tint(.pink)
    }
}
