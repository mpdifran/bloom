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
        HStack(alignment: .center) {
            Image(systemName: focusArea.systemImage)
                .imageScale(.medium)
                .foregroundStyle(.white)
                .frame(square: 35)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(focusArea.color)
                        .aspectRatio(1, contentMode: .fit)
                }
            Text(focusArea.title)
                .bold()

            Spacer()
        }
        .frame(minHeight: 60)
    }
}

#Preview {
    VStack {
        FocusAreaCell(focusArea: .muscleGainAndExercisePerformance)
        FocusAreaCell(focusArea: .sleepBetter)
    }
}
