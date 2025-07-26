//
//  MorningReportView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth
import AppUI
import SwiftData
import DataContainer
import TelemetryDeck

struct MorningReportView: View {
  @State private var viewModel = ViewModel()
  @State private var reportCoordinatorViewModel = ReportCoordinatorViewModel.shared

  @State private var presentedSheet: AnyView?
  @State private var presentedNavPush: AnyView?

  @ObservedObject private var remindersManager = RemindersManager.shared

  @Environment(\.dismiss) private var dismiss

  @Query var reminders: [Reminder]
  @Query private var morningReports: [MorningHealthReport]
  
  init() {
    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
    
    _morningReports = Query(
      filter: #Predicate<MorningHealthReport> { report in
        report.day >= today && report.day < tomorrow
      }
    )

    _reminders = Query(
      sort: \Reminder.modifiedDate,
      order: .reverse
    )
  }

  var body: some View {
    NavigationStack {
      Group {
        if reportCoordinatorViewModel.isLoadingMorningReport {
          loadingSection
        } else if let morningReport = morningReports.first {
          morningReportContent(morningReport)
        } else {
          noReportSection
        }
      }
      .navigationTitle("Morning Report")
      .sheet($presentedSheet)
      .navigationDestination($presentedNavPush)
      .shelf {
        Button(action: {
          dismiss()
        }, label: {
          Text("Done")
            .horizontallyCentered()
        })
        .buttonStyle(.primary)
      }
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .onAppear {
      TelemetryDeck.signal("View Morning Report")
    }
  }
}

private extension MorningReportView {
  
  @ViewBuilder
  var loadingSection: some View {
    VStack(spacing: 20) {
      Spacer()
      CircularSpinnerView()
        .foregroundStyle(.tint)

      Text("Generating Morning Report...")
        .font(.headline)
        .fontDesign(.rounded)
      Spacer()
    }
    .horizontallyCentered()
    .groupedBackground()
  }
  
  @ViewBuilder
  var noReportSection: some View {
    ContentUnavailableView(
      "Morning Report Not Available",
      systemSymbol: .sunrise,
      description: Text("Your morning report will be generated automatically when new health data is available.")
    )
    .groupedBackground()
    .onAppear {
      TelemetryDeck.signal("Morning Report Not Available")
    }
  }
  
  @ViewBuilder
  func morningReportContent(_ report: MorningHealthReport) -> some View {
    BloomScrollView(padding: .vertical) {
      TodaysDateView()
        .padding(.horizontal)

      alertsSection

      Group {
        ReportTitledSection("Readiness") {
          MorningReportReadinessCell(
            readinessScore: report.readinessScore,
            summary: report.readinessSummary ?? ""
          )
        }


        if let todaysFocus = report.todaysFocus, !todaysFocus.isEmpty {
          ReportTitledSection("Todays Focus") {
            MorningReportFocusAreaCell(focusArea: todaysFocus)
          }
        }

        if let sleepFeedback = report.sleepFeedback, !sleepFeedback.isEmpty {
          ReportTitledSection("Sleep") {
            MorningReportSleepCell(sleepSummary: sleepFeedback)
              .selectable()
              .onTapGesture {
                presentedNavPush = SleepDayView(showsChatBar: false).asAny
              }
          }
        }

        if let insights = report.insights {
          insightsSection(insights: insights)
        }
      }
      .padding(.horizontal)

      if viewModel.incompleteReminders.isNotEmpty {
        ReportTitledSection("Missed Reminders", includeExtraTitlePadding: true) {
          TimelineView(.everyMinute) { context in
            ScrollView(.horizontal) {
              HStack {
                ForEach(viewModel.incompleteReminders) { occurrence in
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
                  }
                  .transition(.scale.combined(with: .opacity))
                }
              }
              .scrollTargetLayout()
              .padding(.horizontal)
              .animation(.bouncy(duration: 0.6), value: viewModel.incompleteReminders.map(\.id))
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
          }
        }
      }

      Group {
        ReportTitledSection("Weather") {
          MorningReportWeatherCell()
        }

        ReportTitledSection("Calendar") {
          MorningReportCalendarCell()
        }
      }
      .padding(.horizontal)
    }
  }
  
  @ViewBuilder
  func insightsSection(insights: [MorningHealthInsight]) -> some View {
    if insights.isNotEmpty {
      ReportTitledSection("Insights") {
        VStack(spacing: 12) {
          ForEach(insights, id: \.id) { insight in
            MorningReportInsightCell(
              emoji: insight.emoji ?? "",
              title: insight.title ?? "",
              insight: insight.body ?? ""
            )
          }
        }
      }
    }
  }

  @ViewBuilder
  var alertsSection: some View {
    if viewModel.alerts.isNotEmpty {
      ReportTitledSection("Alerts", includeExtraTitlePadding: true) {
        ScrollView(.horizontal) {
          HStack {
            ForEach(viewModel.alerts) { alert in
              switch alert {
              case .periodPrediction(let date):
                MorningReportPeriodPredictionAlertCell(predictedPeriodDate: date)
                  .onTapGesture {
                    presentedNavPush = MenstruationDetailView().asAny
                  }
              case .intenseActivity(let ratio):
                MorningReportAlertCell(
                  title: "Intense Activity Level (\(ratio.format(using: .oneDecimalPlace)))",
                  message: "Make sure to take a break today to recover.") {
                    Image(systemSymbol: .figureClimbing)
                      .font(.title)
                      .foregroundStyle(.tint)
                  }
                  .tint(.activityLevelIntense)
                  .onTapGesture {
                    presentedNavPush = ActivityLevelDetailsView().asAny
                  }
              case .sedentaryActivity:
                MorningReportAlertCell(
                  title: "Sedentary Activity Level",
                  message: "You've been sedentary for 3 days in a row.") {
                    Image(systemSymbol: .figureStand)
                      .font(.title)
                      .foregroundStyle(.tint)
                  }
                  .tint(.mutedYellow)
                  .onTapGesture {
                    presentedNavPush = ActivityLevelDetailsView().asAny
                  }
              }
            }
          }
          .scrollTargetLayout()
          .padding(.horizontal)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
      }
    }
  }
}

private extension MorningReportView {

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
    MorningReportView()
  }
}
