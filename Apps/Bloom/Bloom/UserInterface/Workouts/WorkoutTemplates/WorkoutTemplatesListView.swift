//
//  WorkoutTemplatesListView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import SwiftUI
import DataContainer
import SwiftData
import HealthKit

struct WorkoutTemplatesListView: View {

  @State private var pushedView: AnyView?
  @State private var error: Error?

  @Query
  private var workoutTemplates: [WorkoutTemplate]

  @Environment(\.modelContext) private var modelContext

  var body: some View {
    BloomScrollView {
      ForEach(workoutTemplates) { workoutTemplate in
        WorkoutTemplateCell(workoutTemplate: workoutTemplate)
          .onTapGesture {
            pushedView = WorkoutTemplateDetailsView(workoutTemplate: workoutTemplate).asAny
          }
          .contextMenu {
            Button("Delete", systemSymbol: .trash, role: .destructive) {
              do {
                try modelContext.savingTransaction {
                  modelContext.delete(workoutTemplate)
                }
              } catch { self.error = error }
            }
            .tint(.red)
          }
      }
    }
    .navigationTitle("Workout Templates")
    .navigationDestination($pushedView)
    .alert(error: $error)
  }
}

#Preview {
  WorkoutTemplatesListView()
}
