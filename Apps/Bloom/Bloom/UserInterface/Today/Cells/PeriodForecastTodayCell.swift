//
//  PeriodForecastTodayCell.swift
//  Bloom
//
//  Created by Assistant on 2025-10-10.
//

import SwiftUI
import CoreHealth

struct PeriodForecastTodayCell: View {
  let forecast: String
  let menstrualSummary: MenstrualSummary?

  private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

  var body: some View {
    TodayCardCell(
      symbol: .calendarBadgeClock,
      title: "Upcoming Period",
      content: forecast,
      color: .mutedPurple
    ) {
      HStack {
        ForEach(weekDays, id: \.self) { date in
          let weekday = Calendar.current.component(.weekday, from: date) - 1
          VStack {
            Text(daysOfWeek[weekday])
              .bold()
              .font(.caption)
              .foregroundStyle(.secondary)

            DayCapsule(
              dayNumber: "\(Calendar.current.component(.day, from: date))",
              highlightKind: highlightKind(for: date),
              isToday: Calendar.current.isDateInToday(date)
            )
          }
        }
      }
    }
  }
}

private extension PeriodForecastTodayCell {

  var cycles: [MenstrualCycle] {
    menstrualSummary?.menstrualCycles ?? []
  }

  var weekDays: [Date] {
    guard let predictedPeriodDate = menstrualSummary?.nextPredictedPeriodDate else {
      // Fallback to current week if no prediction
      return getWeekDays(containing: Date())
    }

    // Always show the week containing the predicted period
    return getWeekDays(containing: predictedPeriodDate)
  }

  func getWeekDays(containing date: Date) -> [Date] {
    guard let sunday = Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start else {
      return []
    }

    return (0..<7).compactMap { dayOffset in
      Calendar.current.date(byAdding: .day, value: dayOffset, to: sunday)
    }
  }

  func highlightKind(for date: Date) -> DayCapsule.HighlightKind {
    // Check for actual menstruation samples (full highlight)
    if cycles.contains(where: { cycle in
      cycle.samples.contains { sample in
        Calendar.current.isDate(date, inSameDayAs: sample.startDate)
      }
    }) {
      return .full
    }

    // Check for predicted ovulation (ring highlight)
    if let predictedOvulationDate = menstrualSummary?.nextPredictedOvulationDate {
      if Calendar.current.isDate(date, inSameDayAs: predictedOvulationDate) {
        return .ring
      }
    }

    // Check for predicted period
    if let predictedPeriodDate = menstrualSummary?.nextPredictedPeriodDate {
      if let difference = Calendar.current.dateComponents([.day], from: date, to: predictedPeriodDate).day {
        // 1-3 days before predicted period: fadedPartial
        if date < predictedPeriodDate, difference <= 3, difference > 0 {
          return .fadedPartial
        }

        let averageMenstruation = menstrualSummary?.averageMenstruationDays ?? 5

        // During predicted menstruation: partial
        if difference <= 0, difference > -(averageMenstruation - 1) {
          return .partial
        }
        // Trailing days after menstruation: fadedPartial
        else if difference <= -(averageMenstruation - 1), difference > -(averageMenstruation + 1) {
          return .fadedPartial
        }
      }
    }

    return .none
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      PeriodForecastTodayCell(
        forecast: "Your period is predicted to start in 3 days, around October 24th. Make sure you have supplies ready!",
        menstrualSummary: nil
      )
    }
  }
}
