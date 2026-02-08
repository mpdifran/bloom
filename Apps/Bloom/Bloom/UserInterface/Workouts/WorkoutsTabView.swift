//
//  WorkoutsTabView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-30.
//

import SwiftUI
import DataContainer
import SwiftData
import HealthKit
import CoreHealth

struct WorkoutsTabView: View {

  @State private var presentedSheet: AnyView?
  @State private var pushedView: AnyView?
  @State private var workouts = [HKWorkout]()
  @State private var error: Error?

  @Query
  private var workoutPlans: [WorkoutPlan]

  @Environment(\.modelContext) private var modelContext
  @Environment(TabController.self) private var tabController

  init() {
    var fetchDescriptor = FetchDescriptor<WorkoutPlan>()
    fetchDescriptor.sortBy = [SortDescriptor(\WorkoutPlan.creationDate, order: .reverse)]
    fetchDescriptor.fetchLimit = 3
    self._workoutPlans = Query(fetchDescriptor)
  }

  var body: some View {
    NavigationStack {
      BloomScrollView {
        TrainingLoadChartView()
        
        workoutTemplatesSection
        workoutsSection
      }
      .navigationTitle("Workouts")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            presentedSheet = WorkoutSettingsView().asAny
          } label: {
            Label("Settings", systemSymbol: .sliderHorizontal3)
          }
          .buttonStyle(.plain)
        }
        SettingsProfileViewToolbarButton()
      }
      .navigationDestination($pushedView)
    }
    .tabItem {
      Label("Workouts", image: .workoutsTab)
    }
    .sheet($presentedSheet)
    .alert(error: $error)
    .task {
      await loadWorkouts()
    }
    .task {
      if let workoutUUID = tabController.pendingWorkoutNavigation {
        tabController.pendingWorkoutNavigation = nil
        await navigateToWorkout(uuid: workoutUUID)
      }
    }
    .onChange(of: tabController.pendingWorkoutNavigation) { _, newValue in
      if let workoutUUID = newValue {
        tabController.pendingWorkoutNavigation = nil
        Task {
          await navigateToWorkout(uuid: workoutUUID)
        }
      }
    }
  }
}

private extension WorkoutsTabView {

  func loadWorkouts() async {
    self.workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: .trailingMonthsFromNow(1000), limit: 3)
  }

  func navigateToWorkout(uuid: String) async {
    guard let workoutUUID = UUID(uuidString: uuid) else { return }

    // Fetch recent workouts and find the one with matching UUID
    let recentWorkouts = await HealthStoreFetcher.shared.fetchWorkouts(
      dateRange: .trailingDaysFromNow(30),
      limit: 100
    )

    if let workout = recentWorkouts.first(where: { $0.uuid == workoutUUID }) {
      pushedView = WorkoutDetailsView(workout: workout).asAny
    }
  }
}

private extension WorkoutsTabView {

  @ViewBuilder
  var workoutTemplatesSection: some View {
    if workoutPlans.isNotEmpty {
      VStack {
        SectionTitleView("Workout Plans")
          .padding(.horizontal)

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

        Button {
          pushedView = WorkoutPlansListView().asAny
        } label: {
          Text("Show All")
            .bold()
            .horizontallyCentered()
            .cardContainer()
        }
      }
    }
  }

  var workoutsSection: some View {
    VStack {
      SectionTitleView("Workouts")
        .padding(.horizontal)

      ForEach(workouts, id: \.hashValue) { workout in
        WorkoutCell(workout: workout)
          .onTapGesture {
            pushedView = WorkoutDetailsView(workout: workout)
              .asAny
          }
      }

      Button {
        pushedView = WorkoutsListView(titleDisplayMode: .inline).asAny
      } label: {
        Text("Show All")
          .bold()
          .horizontallyCentered()
          .cardContainer()
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutsTabView()
  }
}
