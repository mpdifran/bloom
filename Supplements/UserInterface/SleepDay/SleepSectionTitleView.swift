//
//  SleepSectionTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-11.
//

import SwiftUI

struct SleepSectionTitleView: View {
    let title: String
    let systemImage: String
    let isMulticolor: Bool

    init(
        title: String,
        systemImage: String,
        isMulticolor: Bool = false
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isMulticolor = isMulticolor
    }

    var body: some View {
        HStack {
            if isMulticolor {
                Image(systemName: systemImage)
                    .foregroundStyle(.white, .tint)
            } else {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
            }

            Text(title)

            Spacer()
        }
        .font(.title2)
        .bold()
        .fontDesign(.rounded)
    }
}

#Preview {
    List {
        SleepSectionTitleView(
            title: "Heart Rate",
            systemImage: "heart.fill"
        )
    }
    .listStyle(.plain)
}
