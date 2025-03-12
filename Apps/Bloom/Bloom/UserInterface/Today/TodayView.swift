//
//  TodayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-01.
//

import SwiftUI
import AppUI
import SwiftData
import DataContainer

@MainActor
struct TodayView: View {

  init() {
    _habits = Query(
      filter: #Predicate<Habit> { habit in
        habit.endDate == nil
      },
      sort: \Habit.startDate,
      order: .reverse
    )
  }

  @Query var habits: [Habit]

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared
  private var reportViewModel = ReportCoordinatorViewModel.shared
  @ObservedObject private var toDoManager = ToDoManager.shared

  @Environment(TabController.self) private var tabController: TabController

  @State private var presentedFullScreen: AnyView?
  @State private var presentedSheet: AnyView?

  @AppStorage("TodayView.showWeightWidget") private var showWeightWidget: Bool = true
  @AppStorage("TodayView.showNutritionTodayWidget") private var showNutritionTodayWidget: Bool = true
  @AppStorage(.FeatureFlag.danieleMode) private var danieleMode = false
  @AppStorage(.FeatureFlag.legacyGoalSetting) private var legacyGoalSetting = false

  var body: some View {
    @Bindable var tabController = tabController // Hopefully Apple fixes this in the future.

    NavigationStack {
      ScrollView {
        VStack {
          Group {
            TodaysDateView()
              .padding(.bottom)

            alertsSection
          }
          .padding(.horizontal)

          if toDoManager.relevantToDos.isNotEmpty {
            todoSection
          }

          Group {
            if habits.isNotEmpty {
              habitsSection
            }
            reportsSection
          }
          .padding(.horizontal)
        }
        .horizontallyCentered()
      }
      .groupedBackground()
      .navigationTitle("Today")
      .tabBar()
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Settings", systemImage: "person.circle") {
            presentedSheet = SettingsView().asAny
          }
        }
        if danieleMode {
          ToolbarItem(placement: .cancellationAction) {
            Button("Chat", systemImage: "bubble") {
              presentedSheet = ChatView().asAny
            }
            .bold()
          }
        }
      }
      .sheet($presentedSheet)
      .fullScreenCover($presentedFullScreen)
      .fullScreenCover(isPresented: $tabController.showMorningReport) {
        GoodMorningView()
      }
      .fullScreenCover(isPresented: $tabController.showEveningReport) {
        EveningReportView()
      }
      .fullScreenCover(isPresented: $tabController.showFocusAreasReview) {
        FocusAreaReviewRootView()
      }
    }
    .onAppear {
      habitsViewModel.checkUpdateSuggestedHabits()
      Task {
        await toDoManager.recalculateToDos()
      }
    }
    .onForeground {
      habitsViewModel.checkUpdateSuggestedHabits()
      Task {
        await toDoManager.recalculateToDos()
      }
    }
  }
}

private extension TodayView {

  @ViewBuilder
  var alertsSection: some View {
    TimelineView(.everyMinute) { context in
      if Calendar.current.isMorning(date: .now) || danieleMode {
        DailyReportAlertCell(kind: .morning)
          .transition(.scale)
          .onTapGesture {
            presentedFullScreen = GoodMorningView().asAny
          }
      }
      if reportViewModel.shouldShowEveningReport() || danieleMode {
        DailyReportAlertCell(kind: .evening)
          .transition(.scale)
          .onTapGesture {
            presentedFullScreen = EveningReportView().asAny
          }
      }
      if habitsViewModel.shouldUpdateSuggestedHabits || danieleMode {
        GoalReviewCell()
          .transition(.scale)
          .onTapGesture {
            if legacyGoalSetting {
              presentedFullScreen = FocusAreaReviewRootView().asAny
            } else {
              presentedFullScreen = BaseReviewGoalsView().asAny
            }
          }
      }
    }
  }

  @ViewBuilder
  var todoSection: some View {
    SectionTitleView("\(toDoManager.relevantToDos.count) \(toDoManager.relevantToDos.count == 1 ? "To Do" : "To Do's")")
      .padding(.horizontal)
      .padding(.horizontal)

    ScrollView(.horizontal) {
      HStack {
        ForEach(toDoManager.relevantToDos) { todo in
          ToDoActionCard(
            title: todo.kind.name,
            subtitle: todo.cadence.name,
            isComplete: toDoManager.completedToDoKinds.contains(todo.kind),
            vitalKind: todo.vitalKind
          )
          .tint(todo.kind.color)
          .onTapGesture {
            presentedSheet = todo.kind.sheetToPresent
          }
        }
      }
      .scrollTargetLayout()
      .padding(.horizontal)
    }
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  var habitsSection: some View {
    SectionTitleView("Today's Goals")
      .padding(.horizontal)

    ForEach(habits) { habit in
      NavigationLink {
        HabitDetailsView(habit: habit)
      } label: {
        HabitDailyUpdateCell(habit: habit)
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  var reportsSection: some View {
    SectionTitleView("Reports")
      .padding(.horizontal)

    TimelineView(.everyMinute) { context in
      HStack {
        DailyReportCell(
          kind: .morning,
          availabilityText: morningReportCellAvailabilityText
        )
        .onTapGesture {
          guard morningReportCellAvailabilityText == nil else { return }

          presentedSheet = GoodMorningView().asAny
        }

        DailyReportCell(
          kind: .evening,
          availabilityText: eveningReportCellAvailabilityText
        )
        .onTapGesture {
          guard eveningReportCellAvailabilityText == nil else { return }

          presentedSheet = EveningReportView().asAny
        }
      }
    }
  }

  var morningReportCellAvailabilityText: String? {
    guard
      let morningTime = Calendar.current.morningTime(for: .now),
      morningTime > .now
    else {
      return nil
    }

    if
      morningTime.timeIntervalSinceNow > 3600,
      let duration = DateFormatter.timeIntervalHourAbbreviated.string(from: .now, to: morningTime)
    {
      return "Available in \(duration)"
    } else if
      let duration = DateFormatter.timeIntervalMinuteAbbreviated.string(from: .now, to: morningTime)
    {
      return "Available in \(duration)"
    }
    return "Available soon"
  }

  var eveningReportCellAvailabilityText: String? {
    guard
      let eveningReportDate = reportViewModel.eveningReportStartDate,
      eveningReportDate > .now
    else {
      return nil
    }

    if
      eveningReportDate.timeIntervalSinceNow > 3600,
      let duration = DateFormatter.timeIntervalHourAbbreviated.string(from: .now, to: eveningReportDate)
    {
      return "Available in \(duration)"
    } else if
      let duration = DateFormatter.timeIntervalMinuteAbbreviated.string(from: .now, to: eveningReportDate)
    {
      return "Available in \(duration)"
    }
    return "Available soon"
  }
}

#Preview {
  TodayView()
    .environment(TabController())
}
