//
//  FocusAreaCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-04-18.
//

import SwiftUI

struct FocusAreaCell: View {
    let focusArea: FocusAreaModel

    var body: some View {
        HStack {
            Image(systemName: focusArea.systemImage)
                .imageScale(.large)
                .foregroundStyle(.white)
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(focusArea.color)
                }
            Text(focusArea.title)
                .bold()
        }
    }
}

#Preview {
    FocusAreaCell(focusArea: .muscleGainAndExercisePerformance)
}
