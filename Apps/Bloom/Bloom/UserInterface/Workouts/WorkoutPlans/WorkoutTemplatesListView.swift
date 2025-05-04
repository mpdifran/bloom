//
//  WorkoutPlansListView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-30.
//

import SwiftUI
import DataContainer
import SwiftData
import HealthKit

struct WorkoutPlansListView: View {

  @State private var pushedView: AnyView?
  @State private var error: Error?

  @Query
  private var workoutPlans: [WorkoutPlan]

  @Environment(\.modelContext) private var modelContext

  var body: some View {
    BloomScrollView {
      ForEach(workoutPlans) { workoutPlan in
        WorkoutPlanCell(workoutPlan: workoutPlan)
          .onTapGesture {
            pushedView = WorkoutPlanDetailsView(workoutPlan: workoutPlan).asAny
          }
          .contextMenu {
            Button("Delete", systemSymbol: .trash, role: .destructive) {
              do {
                try modelContext.savingTransaction {
                  modelContext.delete(workoutPlan)
                }
              } catch { self.error = error }
            }
            .tint(.red)
          }
      }
    }
    .navigationTitle("Workout Plans")
    .navigationDestination($pushedView)
    .alert(error: $error)
  }
}

#Preview {
  WorkoutPlansListView()
}
