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
    
    _reminders = Query(
      sort: \Reminder.modifiedDate,
      order: .reverse
    )
  }

  @Query var habits: [Habit]
  @Query var reminders: [Reminder]

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared
  private var reportViewModel = ReportCoordinatorViewModel.shared
  @ObservedObject private var remindersManager = RemindersManager.shared

  @Environment(TabController.self) private var tabController: TabController

  @State private var presentedFullScreen: AnyView?
  @State private var presentedSheet: AnyView?

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

        if filteredTodaysOccurrences.isNotEmpty {
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
    }
    .onForeground {
      habitsViewModel.checkUpdateSuggestedHabits()
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
    TimelineView(.everyMinute) { context in
      VStack(alignment: .leading) {
        SectionTitleView(reminderSectionTitle)
          .padding(.horizontal)
          .padding(.horizontal)

        ScrollView(.horizontal) {
          HStack {
            ForEach(sortedOccurrences) { occurrence in
              ReminderCell(
                reminder: occurrence.reminder,
                occurrence: occurrence.occurrence,
                isCompleted: occurrence.isCompleted
              )
              .onTapGesture {
                handleOccurrenceTap(occurrence)
              }
              .contextMenu {
                Button("Edit", systemSymbol: .sliderHorizontal3) {
                  handleEditReminder(occurrence.reminder)
                }
              }
              .transition(.scale.combined(with: .opacity))
            }
          }
          .scrollTargetLayout()
          .padding(.horizontal)
          .animation(.bouncy(duration: 0.6), value: sortedOccurrences.map(\.id))
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
      }
    }
  }

  var reminderSectionTitle: String {
    "\(filteredTodaysOccurrences.count) \(filteredTodaysOccurrences.count == 1 ? "Reminder" : "Reminders")"
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
  
  /// Filtered reminder occurrences that should show on today's view
  var filteredTodaysOccurrences: [ReminderOccurrenceDisplay] {
    let reminderDTOs = reminders.map { $0.asDTO() }
    return reminderDTOs
      .filter { reminder in
        reminder.hasNotificationToday || reminder.isOverdueToday(completionRecords: reminder.completionRecords)
      }
      .flatMap { $0.todaysOccurrenceDisplays() }
  }
  
  var sortedOccurrences: [ReminderOccurrenceDisplay] {
    return filteredTodaysOccurrences.sorted { occurrence1, occurrence2 in
      let isOverdue1 = isOccurrenceOverdue(occurrence1)
      let isOverdue2 = isOccurrenceOverdue(occurrence2)
      let isCompleted1 = occurrence1.isCompleted
      let isCompleted2 = occurrence2.isCompleted
      
      // Both are completed - sort by completion time (most recent first)
      if isCompleted1 && isCompleted2 {
        let completion1 = occurrence1.completionDate
        let completion2 = occurrence2.completionDate
        
        // If we have completion dates, sort by most recent first (descending)
        if let date1 = completion1, let date2 = completion2 {
          return date1 > date2 // Most recent first
        }
        // Fallback to scheduled time (most recent first)
        return occurrence1.scheduledTime > occurrence2.scheduledTime
      }
      
      // One is completed, one is not - uncompleted items come first
      if isCompleted1 != isCompleted2 {
        return !isCompleted1
      }
      
      // Both uncompleted - sort by urgency
      
      // Overdue items first
      if isOverdue1 != isOverdue2 {
        return isOverdue1
      }
      
      // Both not overdue or both overdue - sort by scheduled time
      return occurrence1.scheduledTime < occurrence2.scheduledTime
    }
  }
  
  func isReminderCompleted(_ reminder: ReminderDTO) -> Bool {
    return remindersManager.isReminderCompletedToday(reminder)
  }
  
  func isOccurrenceOverdue(_ occurrence: ReminderOccurrenceDisplay) -> Bool {
    return occurrence.scheduledTime < Date() && !occurrence.isCompleted
  }
  
  func handleReminderTap(_ reminder: ReminderDTO) {
    let isCurrentlyCompleted = isReminderCompleted(reminder)
    
    Task {
      do {
        if isCurrentlyCompleted {
          // Uncomplete the reminder
          try await remindersManager.markReminderUncompleted(withID: reminder.id)
        } else {
          // Complete the reminder
          try await remindersManager.markReminderCompleted(withID: reminder.id)
        }
      } catch {
        print("Failed to mark reminder as \(isCurrentlyCompleted ? "uncompleted" : "completed"): \(error)")
      }
    }
  }
  
  func handleOccurrenceTap(_ occurrence: ReminderOccurrenceDisplay) {
    Task {
      do {
        if occurrence.isCompleted {
          // Uncomplete the reminder (removes the most recent completion)
          try await remindersManager.markReminderUncompleted(withID: occurrence.reminder.id)
        } else {
          // Complete the reminder (adds a new completion)
          try await remindersManager.markReminderCompleted(withID: occurrence.reminder.id)
        }
      } catch {
        print("Failed to mark occurrence as \(occurrence.isCompleted ? "uncompleted" : "completed"): \(error)")
      }
    }
  }
  
  func handleEditReminder(_ reminderDTO: ReminderDTO) {
    // Find the actual Reminder model from the DTO ID
    if let reminder = reminders.first(where: { $0.id == reminderDTO.id }) {
      presentedSheet = CreateEditReminderView(reminder: reminder).asAny
    }
  }
}

#Preview {
  PreviewEnvironment {
    TodayView()
  }
}
