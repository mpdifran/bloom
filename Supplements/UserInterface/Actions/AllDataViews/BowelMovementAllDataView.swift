//
//  BowelMovementAllDataView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SwiftData
import DataContainer

struct BowelMovementAllDataView: View {

    @Query var bowelMovements: [BowelMovement]

    @Environment(\.modelContext) var modelContext

    var body: some View {
        List {
            ForEach(bowelMovements) { bowelMovement in
                HStack {
                    Text(DateFormatter.dateTimeShort.string(from: bowelMovement.date))

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Type \(bowelMovement.bristolStoolType)")
                            .foregroundStyle(.secondary)

                        Text(bowelMovement.duration.name)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .onDelete(perform: deleteBowelMovements)
        }
        .navigationTitle("All Bowel Movements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension BowelMovementAllDataView {

    func deleteBowelMovements(_ indexSet: IndexSet) {
        for index in indexSet {
            let bowelMovement = bowelMovements[index]
            modelContext.delete(bowelMovement)
        }
    }
}

#Preview {
    NavigationStack {
        BowelMovementAllDataView()
    }
}
