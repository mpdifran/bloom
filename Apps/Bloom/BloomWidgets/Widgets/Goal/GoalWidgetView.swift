//
//  GoalWidgetView.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-30.
//

import SwiftUI
import WidgetKit
import BloomUI
import SFSafeSymbols
import BloomFoundation

struct GoalWidgetView: View {
  let entry: GoalEntry
  @Environment(\.widgetFamily) var widgetFamily

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      // Header with goal info
      HStack {
        Image(systemSymbol: SFSymbol(rawValue: entry.systemImage))
          .font(.subheadline)
          .layoutPriority(10)
          .foregroundStyle(.tint)

        VStack(alignment: .leading) {
          Text(entry.goalName)
            .font(.subheadline)
            .bold()
            .lineLimit(1)
          Text("\(entry.targetValue.format(using: .oneDecimalPlace)) \(entry.targetUnit)")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .layoutPriority(1)

        Spacer(minLength: 0)

        if !entry.isLoading {
          Text("\(entry.currentValue.format(using: .oneDecimalPlace))")
            .font(.system(size: 24))
            .minimumScaleFactor(0.8)
            .layoutPriority(10)
            .fontWeight(.heavy)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(.tint)
            .lineLimit(1)
        }
      }

      Spacer(minLength: 0)

      // Goal grid - switch based on time period
      gridView
        .opacity(entry.isLoading ? 0.5 : 1)
        .overlay {
          if entry.isLoading {
            Text("Open Bloom to Refresh")
              .font(.subheadline)
              .bold()
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .padding(12)
              .background {
                RoundedRectangle(cornerRadius: 16)
                  .fill(.regularMaterial)
              }
          }
        }
    }
    .fontDesign(.rounded)
    .widgetURL(URL(string: "https://api.trybloom.app/goals/\(entry.goalId)"))
    .containerBackground(.background, for: .widget)
    .tint(entry.isLoading ? .secondary : colorFromHex(entry.colorHex))
  }
}

private extension GoalWidgetView {

  // MARK: - Grid View

  @ViewBuilder
  var gridView: some View {
    let gridData = entry.isLoading ? loadingGridData : entry.gridData

    switch gridData {
    case .daily(let model):
      GoalGrid(model: model, minCellWidth: 12, spacing: 3)
    case .weekly(let model):
      GoalGridWeek(model: model, minCellWidth: 12, spacing: 3, labelHeight: 12)
    case .monthly(let model):
      GoalGridMonth(model: model, minCellWidth: 40, spacing: 3, labelHeight: 12)
    case .yearly(let model):
      GoalGridYear(model: model, minCellWidth: 60, spacing: 3, labelHeight: 12)
    }
  }

  // MARK: - Helpers

  var loadingGridData: GoalEntry.GridData {
    // Create placeholder grid based on time period
    switch entry.timePeriod {
    case "weekly":
      let weeks = (0..<20).map { weekOffset in
        GoalGridWeekModel.Week(
          id: weekOffset,
          isComplete: nil,
          isCurrentWeek: false,
          monthLabel: nil
        )
      }
      return .weekly(GoalGridWeekModel(weeks: weeks))

    case "monthly":
      let months = (0..<12).map { monthOffset in
        GoalGridMonthModel.Month(
          id: monthOffset,
          isComplete: nil,
          isCurrentMonth: false,
          monthLabel: ""
        )
      }
      return .monthly(GoalGridMonthModel(months: months))

    case "yearly":
      let years = (0..<5).map { yearOffset in
        GoalGridYearModel.Year(
          id: yearOffset,
          isComplete: nil,
          isCurrentYear: false,
          yearLabel: ""
        )
      }
      return .yearly(GoalGridYearModel(years: years))

    default: // "daily"
      let weeks = (0..<40).map { weekOffset in
        GoalGridModel.Week(
          id: weekOffset,
          isComplete: Array(repeating: false, count: 7),
          todayIndex: nil
        )
      }
      return .daily(GoalGridModel(weeks: weeks))
    }
  }

  func colorFromHex(_ hex: String) -> Color {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (r, g, b) = (255, 107, 107) // Default to mutedPink
    }
    return Color(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: 1
    )
  }
}
