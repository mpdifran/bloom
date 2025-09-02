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
import BloomModel

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
  @ObservedObject private var remindersManager = RemindersManager.shared
  @State private var todayViewModel = ViewModel.shared

  @Environment(TabController.self) private var tabController: TabController

  @State private var presentedFullScreen: AnyView?
  @State private var presentedSheet: AnyView?
  @State private var presentedNavPush: AnyView?
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @TodaySettingsStorage("TodayView.settings") private var todaySettings = TodaySettings()
  @State private var currentTimeMode: TimeMode = .morning

  @AppStorage("TodayView.showWeightWidget") private var showWeightWidget: Bool = true
  @AppStorage("TodayView.showNutritionTodayWidget") private var showNutritionTodayWidget: Bool = true
  @AppStorage("GetBloomPlusTodayCell.hasDismissed") private var getBloomPlusHasDismissed = false

  @State private var sceneryScale: CGFloat = 1

  var body: some View {
    @Bindable var tabController = tabController // Hopefully Apple fixes this in the future.

    NavigationStack {
      TimelineView(.everyMinute) { context in
        BloomScrollView(padding: .bottom) {
          ZStack {
            currentSceneryImage
              .resizable()
              .scaledToFit()
              .allowsHitTesting(false)
              .compositingGroup()
              .drawingGroup()
              .scaleEffect(sceneryScale, anchor: .bottom)
              .zStackAlignment(.top)

            VStack {
              if todayViewModel.hasBloomPlus {
                bloomPlusContent
              } else {
                nonBloomPlusContent
              }

              configureButton
            }
            .padding(.top, 160)
          }
        }
        .ignoresSafeArea(.all, edges: .top)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
          geometry.contentOffset.y
        } action: { oldValue, newValue in
          if newValue < 0 {
            sceneryScale = (newValue - 200) / -200
          }
        }
        .onAppear {
          currentTimeMode = TimeMode.current(for: context.date, settings: todaySettings)
        }
        .onChange(of: context.date) { _, newDate in
          currentTimeMode = TimeMode.current(for: newDate, settings: todaySettings)
        }
      }
      .navigationTitle("Today")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            presentedSheet = SettingsView().asAny
          } label: {
            UserProfilePhotoView(
              dimension: 32,
              whiteForegroundColor: true
            )
          }
        }
        
//        ToolbarItem(placement: .topBarLeading) {
//          Button {
//            presentedSheet = TodaySettingsView().asAny
//          } label: {
//            Image(systemSymbol: .sliderHorizontal3)
//              .foregroundStyle(.white)
//              .bold()
//              .padding(6)
//              .background {
//                RoundedRectangle(cornerRadius: 10)
//                  .fill(.tint)
//              }
//          }
//        }
      }
      .sheet($presentedSheet)
      .navigationDestination($presentedNavPush)
      .fullScreenCover($presentedFullScreen)
      .fullScreenCover(isPresented: $tabController.showPaywall) {
        BloomPlusPaywall()
      }
      .confirmationDialog($confirmationDialogDetails)
    }
    .animation(.default, value: todayViewModel.todayContent)
    .animation(.default, value: todayViewModel.isLoadingContent)
    .animation(.default, value: todayViewModel.hasLoadError)
    .animation(.default, value: getBloomPlusHasDismissed)
    .onAppear {
      habitsViewModel.checkUpdateSuggestedHabits()
      Task {
        todayViewModel.checkEntitlement()
        await todayViewModel.requestContentIfNeeded()
      }
    }
    .onForeground {
      habitsViewModel.checkUpdateSuggestedHabits()
      Task {
        todayViewModel.checkEntitlement()
        await todayViewModel.requestContentIfNeeded()
      }
    }
  }
}

private extension TodayView {
  
  var currentSceneryImage: Image {
    switch currentTimeMode {
    case .morning:
      return Image(.morningScenery)
    case .afternoon:
      return Image(.afternoonScenery)
    case .evening:
      return Image(.eveningScenery)
    case .night:
      return Image(.nightScenery)
    }
  }
  
  @ViewBuilder
  var bloomPlusContent: some View {
    VStack {
      // Hero section with Bud and summary
      if todayViewModel.todayContent != nil || todayViewModel.isLoadingContent || todayViewModel.hasLoadError {
        TodayHeroCell(
          budState: todayViewModel.budState,
          summary: todayViewModel.todayContent?.summary,
          hasError: todayViewModel.hasLoadError,
          isLoading: todayViewModel.todayContent == nil,
          onReload: {
            await todayViewModel.retryLoadContent()
          }
        )
        .padding(.horizontal)
      }
      
      // Dynamic sections based on time mode and settings
      let configuration = todaySettings.configuration(for: currentTimeMode)
      ForEach(configuration.sectionOrder) { section in
        // Only show enabled sections that user has access to
        let hasAccess = !section.requiresBloomPlus || todayViewModel.hasBloomPlus
        if configuration.enabledSections.contains(section) && hasAccess {
          sectionView(for: section)
        }
      }
    }
  }
  
  @ViewBuilder
  var nonBloomPlusContent: some View {
    VStack {
      TodayHeroCell(
        budState: .proudCoach,
        summary: nil,
        hasError: false,
        isLoading: false,
        onReload: nil
      )
      .padding(.horizontal)

      // Show sections based on settings but only those available without Bloom Plus
      let configuration = todaySettings.configuration(for: currentTimeMode)
      ForEach(configuration.sectionOrder) { section in
        // Only show sections that don't require Bloom Plus
        if configuration.enabledSections.contains(section) && !section.requiresBloomPlus {
          sectionView(for: section)
        }
      }
      
      // Show Bloom Plus upsell at the bottom if not dismissed
      if !getBloomPlusHasDismissed {
        GetBloomPlusTodayCell()
          .padding(.horizontal)
      }
    }
  }

  var configureButton: some View {
    Button {
      presentedSheet = TodaySettingsView().asAny
    } label: {
      Label("Configure", systemSymbol: .sliderHorizontal3)
    }
    .buttonStyle(.secondary)
    .padding()
  }

  @ViewBuilder
  func sectionView(for section: TodaySection) -> some View {
    switch section {
    case .todaysAdvice:
      if let content = todayViewModel.getSectionContent(for: section),
         case .text(let advice) = content {
        TodaysAdviceTodayCell(advice: advice)
          .padding(.horizontal)
          .padding(.top)
      }
      
    case .insights:
      if let content = todayViewModel.getSectionContent(for: section),
         case .insights(let insights) = content {

        SectionTitleView("Insights")
          .padding(.horizontal)
          .padding(.horizontal)
        InsightTodayCell(insights: insights)
      }
      
    case .sleepDetails:
      if let content = todayViewModel.getSectionContent(for: section),
         case .text(let details) = content {
        SectionTitleView("Sleep Summary")
          .padding(.horizontal)
          .padding(.horizontal)
        SleepSummaryTodayCell(summary: details)
          .onTapGesture {
            presentedNavPush = SleepDayView(showsChatBar: true).asAny
          }
          .padding(.horizontal)
      }
      
    case .tonightsSleep:
      if let content = todayViewModel.getSectionContent(for: section),
         case .text(let recommendations) = content {
        TonightsSleepTodayCell(recommendations: recommendations)
          .padding(.horizontal)
      }
      
    case .goals:
      if habits.isNotEmpty {
        Group {
          habitsSection
        }
        .padding(.horizontal)
      }
      
    case .reminders:
      remindersSection
      
    case .todaysEvents:
      SectionTitleView("Today's Events")
        .padding(.horizontal)
        .padding(.horizontal)
      CalendarTodayCell(day: .today)
        .padding(.horizontal)
      
    case .tomorrowsEvents:
      SectionTitleView("Tomorrow's Events")
        .padding(.horizontal)
        .padding(.horizontal)
      CalendarTodayCell(day: .tomorrow)
        .padding(.horizontal)
      
    case .todaysWeather:
      SectionTitleView("Today's Weather")
        .padding(.horizontal)
        .padding(.horizontal)
      WeatherTodayCell(day: .today)
        .padding(.horizontal)
      
    case .tomorrowsWeather:
      SectionTitleView("Tomorrow's Weather")
        .padding(.horizontal)
        .padding(.horizontal)
      WeatherTodayCell(day: .tomorrow)
        .padding(.horizontal)
    }
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
                scheduledTime: occurrence.scheduledTime,
                isCompleted: occurrence.isCompleted
              )
              .onTapGesture {
                handleOccurrenceTap(occurrence)
              }
              .contextMenu {
                Button("Edit", systemSymbol: .sliderHorizontal3) {
                  handleEditReminder(occurrence.reminder)
                }
                Divider()
                Button("Delete", systemSymbol: .trash, role: .destructive) {
                  confirmationDialogDetails = ConfirmationDialogDetails(
                    title: "Delete Reminder",
                    message: "Are you sure you want to delete \"\(occurrence.reminder.title)\"? This action cannot be undone.",
                    buttons: [
                      ConfirmationDialogDetails.Button(title: "Delete", role: .destructive) {
                        Task {
                          do {
                            try await remindersManager.deleteReminder(withID: occurrence.reminder.id)
                          } catch {
                            print("Failed to delete reminder: \(error)")
                          }
                        }
                      }
                    ]
                  )
                }
                .tint(.red)
              }
              .transition(.scale.combined(with: .opacity))
            }

            AddReminderCell()
              .onTapGesture {
                presentedSheet = CreateEditReminderView().asAny
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
    let totalCount = filteredTodaysOccurrences.count
    let completedCount = filteredTodaysOccurrences.filter { $0.isCompleted }.count
    
    let reminderText = totalCount == 1 ? "reminder" : "reminders"
    
    if completedCount > 0 {
      return "\(totalCount) \(reminderText) • \(completedCount) completed"
    } else {
      return "\(totalCount) \(reminderText)"
    }
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

          EntitledPresent(presentedSheet: $presentedSheet) {
            MorningReportView(rootPresentedSheet: $presentedSheet)
          }
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
          // Uncomplete the reminder (removes the completion for this specific occurrence)
          try await remindersManager.markReminderUncompleted(
            withID: occurrence.reminder.id,
            occurrenceID: occurrence.occurrence.id
          )
        } else {
          // Complete the reminder (adds a new completion for this specific occurrence)
          try await remindersManager.markReminderCompleted(
            withID: occurrence.reminder.id,
            occurrenceID: occurrence.occurrence.id
          )
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
