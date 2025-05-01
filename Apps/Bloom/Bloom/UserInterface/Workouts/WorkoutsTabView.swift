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

  @Environment(TabController.self) private var tabController: TabController

  @State private var presentedSheet: AnyView?
  @State private var pushedView: AnyView?
  @State private var workouts = [HKWorkout]()
  @State private var error: Error?

  @Query
  private var workoutTemplates: [WorkoutTemplate]

  @Environment(\.modelContext) private var modelContext

  init() {
    var fetchDescriptor = FetchDescriptor<WorkoutTemplate>()
    fetchDescriptor.sortBy = [SortDescriptor(\WorkoutTemplate.creationDate, order: .reverse)]
    fetchDescriptor.fetchLimit = 3
    self._workoutTemplates = Query(fetchDescriptor)
  }

  var body: some View {
    NavigationStack {
      BloomScrollView {
        workoutTemplatesSection
        workoutsSection
      }
      .navigationTitle("Workouts")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            presentedSheet = SettingsView().asAny
          } label: {
            UserProfilePhotoView(dimension: 32)
          }
        }
      }
      .safeAreaPadding(.bottom, tabController.chatLauncherSafeAreaInset)
      .navigationDestination($pushedView)
    }
    .sheet($presentedSheet)
    .alert(error: $error)
    .task {
      await loadWorkouts()
    }
  }
}

private extension WorkoutsTabView {

  func loadWorkouts() async {
    self.workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: .trailingMonthsFromNow(1000), limit: 3)
  }
}

private extension WorkoutsTabView {

  @ViewBuilder
  var workoutTemplatesSection: some View {
    if workoutTemplates.isNotEmpty {
      VStack {
        SectionTitleView("Workout Templates")
          .padding(.horizontal)

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

        Button {
          pushedView = WorkoutTemplatesListView().asAny
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
