//
//  FocusAreaView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-04-18.
//

import SwiftUI

struct FocusAreaView: View {
    let focusArea: FocusAreaModel

    var body: some View {
        List {
            if !focusArea.unproven.isEmpty {
                Section("Unproven Supplements") {
                    ForEach(focusArea.unproven) { supplement in
                        NavigationLink {
                            SupplementView(supplement: supplement.supplement)
                        } label: {
                            Label(supplement.supplement.name, systemImage: "pill.fill")
                        }

                        Label(supplement.context, systemImage: "info.circle.fill")
                    }
                }
            }
        }
        .navigationTitle(focusArea.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FocusAreaView(focusArea: .muscleGainAndExercisePerformance)
    }
}
