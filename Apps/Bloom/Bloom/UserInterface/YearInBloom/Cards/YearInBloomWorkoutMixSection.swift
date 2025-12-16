//
//  YearInBloomWorkoutMixSection.swift
//  Bloom
//
//  Created by Claude on 2025-12-12.
//

import SwiftUI
import Charts
import CoreHealth

/// Workout Mix Section
/// Shows stacked area chart of workout type distribution per month
struct YearInBloomWorkoutMixSection: View {
  let stats: YearInBloomWorkoutStats

  private let workoutColors: [Color] = [
    .mutedGreen,
    .mutedPink,
    .mutedIndigo,
    .mutedTeal,
    .mutedYellow
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerSection
      chartSection
      insightSection
    }
  }
}

// MARK: - Header Section

private extension YearInBloomWorkoutMixSection {

  var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Your Workout Mix")
        .font(.title)
        .bold()
        .fontDesign(.rounded)

      Text("\(stats.year)")
        .font(.title2)
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
    }
  }
}

// MARK: - Chart Section

private extension YearInBloomWorkoutMixSection {

  var chartSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Legend
      legendView

      // Stacked bar chart
      Chart {
        ForEach(chartData) { item in
          BarMark(
            x: .value("Month", item.date, unit: .month),
            y: .value("Hours", item.value)
          )
          .foregroundStyle(colorForCategory(item.category))
        }
      }
      .chartXAxis {
        AxisMarks(values: .stride(by: .month)) { _ in
          AxisValueLabel(format: .dateTime.month(.abbreviated))
        }
      }
      .chartYAxis {
        AxisMarks { value in
          AxisGridLine()
            .foregroundStyle(.secondary.opacity(0.3))
          if let doubleValue = value.as(Double.self) {
            AxisValueLabel {
              Text("\(Int(doubleValue))h")
            }
          }
        }
      }
      .chartLegend(.hidden)
      .frame(height: 220)
    }
    .padding()
    .cardContainer()
  }

  var legendView: some View {
    let types = Array(sortedWorkoutTypes.prefix(5))

    return FlowLayout(spacing: 8) {
      ForEach(Array(types.enumerated()), id: \.element.activityName) { index, type in
        HStack(spacing: 4) {
          Circle()
            .fill(workoutColors[index % workoutColors.count])
            .frame(width: 8, height: 8)
          Text(type.activityName)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .fontDesign(.rounded)
      }
    }
  }

  var sortedWorkoutTypes: [WorkoutTypeStats] {
    stats.topWorkoutTypes.sorted { $0.totalDurationMinutes > $1.totalDurationMinutes }
  }

  func colorForCategory(_ category: String) -> Color {
    let types = Array(sortedWorkoutTypes.prefix(5))
    if let index = types.firstIndex(where: { $0.activityName == category }) {
      return workoutColors[index % workoutColors.count]
    }
    return .gray.opacity(0.5)
  }

  var chartData: [WorkoutChartItem] {
    var items = [WorkoutChartItem]()
    let topTypeNames = Set(sortedWorkoutTypes.prefix(5).map(\.activityName))

    for monthly in stats.monthlyStats {
      guard let date = Calendar.current.date(from: DateComponents(year: stats.year, month: monthly.month, day: 15)) else {
        continue
      }

      // Group by workout type
      var typeHours = [String: Double]()
      var otherHours = 0.0

      for typeStats in monthly.workoutTypeBreakdown {
        if topTypeNames.contains(typeStats.activityName) {
          typeHours[typeStats.activityName, default: 0] += typeStats.totalDurationMinutes / 60
        } else {
          otherHours += typeStats.totalDurationMinutes / 60
        }
      }

      // Add items for each type
      for typeName in topTypeNames {
        items.append(WorkoutChartItem(
          date: date,
          category: typeName,
          value: typeHours[typeName, default: 0]
        ))
      }

      // Add "Other" if there's any
      if otherHours > 0 {
        items.append(WorkoutChartItem(
          date: date,
          category: "Other",
          value: otherHours
        ))
      }
    }

    return items
  }
}

// MARK: - Insight Section

private extension YearInBloomWorkoutMixSection {

  var insightSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Top workout type callout
      if let topType = stats.topWorkoutTypes.first {
        topTypeCard(topType)
      }

      // Variety stat
      varietyCard
    }
  }

  func topTypeCard(_ type: WorkoutTypeStats) -> some View {
    HStack(spacing: 12) {
      Circle()
        .fill(.mutedGreen)
        .frame(width: 40, height: 40)
        .overlay {
          Text("\(Int(type.percentage))%")
            .font(.caption)
            .bold()
            .foregroundStyle(.white)
        }

      VStack(alignment: .leading, spacing: 2) {
        Text("Your go-to workout")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(type.activityName)
          .font(.title3)
          .bold()
      }
      .fontDesign(.rounded)

      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color.mutedGreen.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  var varietyCard: some View {
    HStack(spacing: 12) {
      Image(systemName: "sparkles")
        .font(.title2)
        .foregroundStyle(.mutedIndigo)

      VStack(alignment: .leading, spacing: 2) {
        Text("Workout variety")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("**\(stats.yearTotals.uniqueWorkoutTypes)** different workout types")
          .font(.headline)
      }
      .fontDesign(.rounded)

      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color.mutedIndigo.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - Supporting Types

private struct WorkoutChartItem: Identifiable {
  let id = UUID()
  let date: Date
  let category: String
  let value: Double
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    return layout(sizes: sizes, proposal: proposal).size
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    let positions = layout(sizes: sizes, proposal: proposal).positions

    for (index, subview) in subviews.enumerated() {
      subview.place(
        at: CGPoint(x: bounds.minX + positions[index].x, y: bounds.minY + positions[index].y),
        proposal: .unspecified
      )
    }
  }

  private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (size: CGSize, positions: [CGPoint]) {
    var positions = [CGPoint]()
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var lineHeight: CGFloat = 0
    let maxWidth = proposal.width ?? .infinity

    for size in sizes {
      if currentX + size.width > maxWidth && currentX > 0 {
        currentX = 0
        currentY += lineHeight + spacing
        lineHeight = 0
      }

      positions.append(CGPoint(x: currentX, y: currentY))
      currentX += size.width + spacing
      lineHeight = max(lineHeight, size.height)
    }

    let totalHeight = currentY + lineHeight
    let totalWidth = sizes.map(\.width).max() ?? 0

    return (CGSize(width: min(maxWidth, totalWidth), height: totalHeight), positions)
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    YearInBloomWorkoutMixSection(stats: .preview)
  }
}
