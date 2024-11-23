//
//  DebugFoodItemLogListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import SwiftUI
import SwiftData
import DataContainer

struct DebugFoodItemLogListView: View {

    @Query(sort: \FoodItemLog.date, order: .reverse) var foodItemLogs: [FoodItemLog]

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(foodItemLogs) { log in
                    DebugFoodItemLogCell(foodItemLog: log)
                }
                .onDelete(perform: deleteLogs)
            }
            .navigationTitle("Debug Food Item Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension DebugFoodItemLogListView {

    func deleteLogs(_ indexSet: IndexSet) {
        try? modelContext.transaction {
            for index in indexSet {
                let foodItemLog = foodItemLogs[index]
                modelContext.delete(foodItemLog)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DebugFoodItemLogListView()
    }
}
