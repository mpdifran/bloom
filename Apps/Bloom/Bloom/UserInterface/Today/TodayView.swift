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
import SFSafeSymbols
import BloomFoundation

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
  @ObservedObject private var remindersManager = RemindersManager.shared

  @Environment(TabController.self) private var tabController: TabController

  @State private var presentedFullScreen: AnyView?
  @State private var presentedSheet: AnyView?
  @State private var todaysReminders: [ReminderDTO] = []
  @State private var completedReminderIDs: Set<String> = []
  @State private var recentlyCompletedReminderIDs: Set<String> = []

  @AppStorage("TodayView.showWeightWidget") private var showWeightWidget: Bool = true
  @AppStorage("TodayView.showNutritionTodayWidget") private var showNutritionTodayWidget: Bool = true
  @AppStorage(.FeatureFlag.alwaysShowReports) private var alwaysShowReports = false
  @AppStorage(.FeatureFlag.legacyGoalSetting) private var legacyGoalSetting = false

  var body: some View {
    @Bindable var tabController = tabController // Hopefully Apple fixes this in the future.

    NavigationStack {
      BloomScrollView(padding: .bottom) {
        Group {
          TodaysDateView()
            .padding(.bottom)

          alertsSection
        }
        .padding(.horizontal)

        if todaysReminders.isNotEmpty {
          remindersSection
        }

        Group {
          if habits.isNotEmpty {
            habitsSection
          }

          if !shouldShowMorningReportAlert {
            reportsSection
          }
        }
        .padding(.horizontal)
      }
      .navigationTitle("Today")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            presentedSheet = SettingsView().asAny
          } label: {
            UserProfilePhotoView(dimension: 32)
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
        if legacyGoalSetting {
          FocusAreaReviewRootView()
        } else {
          BaseReviewGoalsView()
        }
      }
      .fullScreenCover(isPresented: $tabController.showPaywall) {
        BloomPlusPaywall()
      }
    }
    .onAppear {
      habitsViewModel.checkUpdateSuggestedHabits()
      Task {
        await loadTodaysReminders()
      }
    }
    .onForeground {
      habitsViewModel.checkUpdateSuggestedHabits()
      Task {
        await loadTodaysReminders()
      }
    }
  }
}

private extension TodayView {

  @ViewBuilder
  var alertsSection: some View {
    TimelineView(.everyMinute) { context in
      if shouldShowMorningReportAlert {
        DailyReportAlertCell(kind: .morning)
          .transition(.scale)
          .onTapGesture {
            presentedFullScreen = GoodMorningView().asAny
          }
      }
    }
  }

  var shouldShowMorningReportAlert: Bool {
    Calendar.current.isMorning(date: .now) || alwaysShowReports
  }

  @ViewBuilder
  var remindersSection: some View {
    SectionTitleView("\(todaysReminders.count) \(todaysReminders.count == 1 ? "Reminder" : "Reminders")")
      .padding(.horizontal)
      .padding(.horizontal)

    ScrollView(.horizontal) {
      HStack {
        ForEach(sortedReminders) { reminder in
          ReminderCell(
            reminder: reminder,
            isCompleted: isReminderCompleted(reminder)
          )
          .onTapGesture {
            handleReminderTap(reminder)
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

        Spacer()
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
  
  // MARK: - Reminder Helpers
  
  func loadTodaysReminders() async {
    do {
      // Fetch ALL reminders first, then filter for today's + overdue
      await remindersManager.fetchReminders()
      let allReminders = remindersManager.reminders
      
      if allReminders.isEmpty {
        await MainActor.run {
          todaysReminders = []
          updateCompletedReminderIDs()
        }
        return
      }
      
      // Filter to only show reminders that have notifications today or are overdue
      let filteredReminders = allReminders.filter { reminder in
        hasNotificationToday(reminder) || isOverdue(reminder)
      }
      
      await MainActor.run {
        todaysReminders = filteredReminders
        updateCompletedReminderIDs()
      }
    } catch {
      print("Failed to load today's reminders: \(error)")
    }
  }
  
  func hasNotificationToday(_ reminder: ReminderDTO) -> Bool {
    guard let nextNotificationDate = reminder.nextNotificationDate else { return false }
    return Calendar.current.isDateInToday(nextNotificationDate)
  }
  
  func isOverdue(_ reminder: ReminderDTO) -> Bool {
    guard let nextDate = reminder.nextNotificationDate else { return false }
    let isCompleted = remindersManager.isReminderCompletedToday(reminder)
    return nextDate < Date() && !isCompleted
  }
  
  func updateCompletedReminderIDs() {
    completedReminderIDs = Set(
      todaysReminders
        .filter { remindersManager.isReminderCompletedToday($0) }
        .map { $0.id }
    )
  }
  
  var sortedReminders: [ReminderDTO] {
    return todaysReminders.sorted { reminder1, reminder2 in
      let isOverdue1 = isOverdue(reminder1)
      let isOverdue2 = isOverdue(reminder2)
      let isCompleted1 = isReminderCompleted(reminder1)
      let isCompleted2 = isReminderCompleted(reminder2)
      
      // If one is completed and recently completed, keep it in place temporarily
      if recentlyCompletedReminderIDs.contains(reminder1.id) && !recentlyCompletedReminderIDs.contains(reminder2.id) {
        return true
      }
      if recentlyCompletedReminderIDs.contains(reminder2.id) && !recentlyCompletedReminderIDs.contains(reminder1.id) {
        return false
      }
      
      // If both recently completed or neither, normal sorting applies
      
      // Overdue items first (unless completed)
      if isOverdue1 && !isCompleted1 && !(isOverdue2 && !isCompleted2) {
        return true
      }
      if isOverdue2 && !isCompleted2 && !(isOverdue1 && !isCompleted1) {
        return false
      }
      
      // Within overdue items, sort by most overdue (earliest missed notification)
      if isOverdue1 && !isCompleted1 && isOverdue2 && !isCompleted2 {
        let lastMissed1 = reminder1.lastMissedNotificationDate ?? Date.distantPast
        let lastMissed2 = reminder2.lastMissedNotificationDate ?? Date.distantPast
        return lastMissed1 < lastMissed2
      }
      
      // Completed items at the end
      if isCompleted1 && !isCompleted2 {
        return false
      }
      if isCompleted2 && !isCompleted1 {
        return true
      }
      
      // For non-overdue items, sort by next notification time
      let nextTime1 = reminder1.nextNotificationDate ?? Date.distantFuture
      let nextTime2 = reminder2.nextNotificationDate ?? Date.distantFuture
      return nextTime1 < nextTime2
    }
  }
  
  func isReminderCompleted(_ reminder: ReminderDTO) -> Bool {
    return completedReminderIDs.contains(reminder.id)
  }
  
  func handleReminderTap(_ reminder: ReminderDTO) {
    // Provide success haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()
    
    // Mark as completed
    Task {
      do {
        try await remindersManager.markReminderCompleted(withID: reminder.id)
        
        await MainActor.run {
          completedReminderIDs.insert(reminder.id)
          recentlyCompletedReminderIDs.insert(reminder.id)
        }
        
        // After 2 seconds, remove from recently completed and allow re-sorting
        try await Task.sleep(for: .seconds(2))
        
        await MainActor.run {
          recentlyCompletedReminderIDs.remove(reminder.id)
        }
      } catch {
        print("Failed to mark reminder as completed: \(error)")
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    TodayView()
  }
}
