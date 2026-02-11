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
import AppUI

struct WorkoutsTabView: View {

  enum WorkoutsTab: CaseIterable, Hashable {
    case workouts
    case workoutPlans

    var title: String {
      switch self {
      case .workouts: "Workouts"
      case .workoutPlans: "Plans"
      }
    }
  }

  @State private var selectedTab: WorkoutsTab = .workouts
  @State private var presentedSheet: AnyView?
  @State private var pushedView: AnyView?
  @State private var workoutSections = [WorkoutDaySection]()
  @State private var trainingLoadSummary: TrainingLoadSummary?
  @State private var error: Error?

  @Query
  private var workoutPlans: [WorkoutPlan]

  @Environment(\.modelContext) private var modelContext
  @Environment(TabController.self) private var tabController

  init() {
    var fetchDescriptor = FetchDescriptor<WorkoutPlan>()
    fetchDescriptor.sortBy = [SortDescriptor(\WorkoutPlan.creationDate, order: .reverse)]
    self._workoutPlans = Query(fetchDescriptor)
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(padding: .vertical) {
        TrainingLoadChartView(summary: trainingLoadSummary)

        Group {
          Picker("Section", selection: $selectedTab) {
            ForEach(WorkoutsTab.allCases, id: \.self) { tab in
              Text(tab.title).tag(tab)
            }
          }
          .pickerStyle(.segmented)
          .padding(.top)

          switch selectedTab {
          case .workouts:
            workoutsSection
          case .workoutPlans:
            workoutTemplatesSection
          }
        }
        .padding(.horizontal)
      }
      .animation(.easeInOut, value: selectedTab)
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
      await loadTrainingLoad()
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

  func loadTrainingLoad() async {
    await TrainingLoadCalculator.shared.refreshTrainingLoad()
    trainingLoadSummary = await TrainingLoadCalculator.shared.trainingLoadSummary
  }

  func loadWorkouts() async {
    let workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: .trailingDaysFromNow(7))
    let grouped = Dictionary(grouping: workouts) { workout in
      Calendar.current.startOfDay(for: workout.startDate)
    }
    self.workoutSections = grouped
      .map { WorkoutDaySection(date: $0.key, workouts: $0.value.sorted { $0.startDate > $1.startDate }) }
      .sorted { $0.date > $1.date }
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

  var workoutTemplatesSection: some View {
    VStack {
      Button {
        EntitledPresent(presentedSheet: $presentedSheet) {
          CreateWorkoutPlanView()
        }
      } label: {
        Label("Create A Plan", systemSymbol: .sparkles)
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .tint(.blue)
      .padding(.vertical)

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
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
    }
  }

  var workoutsSection: some View {
    VStack {
      ForEach(workoutSections) { section in
        WorkoutDaySectionHeaderView(date: section.date)
          .padding(.horizontal)

        ForEach(section.workouts, id: \.hashValue) { workout in
          WorkoutCell(workout: workout)
            .onTapGesture {
              pushedView = WorkoutDetailsView(workout: workout)
                .asAny
            }
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
      .padding(.top)
    }
  }
}

private struct WorkoutDaySection: Identifiable {
  var id: Date { date }

  let date: Date
  let workouts: [HKWorkout]
}

private struct WorkoutDaySectionHeaderView: View {
  let date: Date

  var body: some View {
    VStack(alignment: .leading) {
      Text(DateFormatter.justRelativeDayOfWeek(date: date))
        .font(.title)
        .bold()
      Text(date, formatter: DateFormatter.justDateMedium)
        .foregroundStyle(.secondary)
        .font(.headline)
        .bold()
    }
    .fontDesign(.rounded)
    .padding(.top)
    .horizontalAlignment(.leading)
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutsTabView()
  }
}
