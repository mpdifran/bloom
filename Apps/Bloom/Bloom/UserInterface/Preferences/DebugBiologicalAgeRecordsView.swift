//
//  DebugBiologicalAgeRecordsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-03.
//

import SwiftUI
import SwiftData
import DataContainer

struct DebugBiologicalAgeRecordsView: View {

  @Query(sort: \BiologicalAgeRecord.date, order: .reverse) var records: [BiologicalAgeRecord]

  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      List {
        ForEach(records) { record in
          VStack(alignment: .leading, spacing: 4) {
            Text(record.date, format: .dateTime.month().day().year().hour().minute())
              .font(.headline)
              .fontDesign(.rounded)

            HStack {
              Text("Bio Age: \(Int(record.biologicalAge))")
              Spacer()
              Text("Actual: \(Int(record.actualAge))")
              Spacer()
              let delta = record.biologicalAge - record.actualAge
              Text(delta >= 0 ? "+\(String(format: "%.1f", delta))" : "\(String(format: "%.1f", delta))")
                .foregroundStyle(delta <= 0 ? .green : .orange)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }
        .onDelete(perform: deleteRecords)
      }
      .navigationTitle("Biological Age Records")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .overlay {
        if records.isEmpty {
          ContentUnavailableView(
            "No Records",
            systemImage: "heart.text.square",
            description: Text("Biological age records will appear here after calculations.")
          )
        }
      }
    }
  }
}

private extension DebugBiologicalAgeRecordsView {

  func deleteRecords(_ indexSet: IndexSet) {
    for index in indexSet {
      let record = records[index]
      modelContext.delete(record)
      try? modelContext.save()
    }
  }
}

#Preview {
  DebugBiologicalAgeRecordsView()
}
