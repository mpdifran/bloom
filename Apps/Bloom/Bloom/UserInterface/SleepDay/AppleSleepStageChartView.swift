//
//  AppleSleepStageChartView.swift
//  Bloom
//
//  Created by Claude on 2026-01-22.
//

import SwiftUI
import CoreHealth
import BloomFoundation
@preconcurrency import HealthKit

// MARK: - Apple Sleep Stage Model

enum AppleSleepStage: Int, CaseIterable {
  case awake = 0
  case rem = 1
  case core = 2
  case deep = 3

  var color: Color {
    switch self {
    case .awake: .awakeSleep
    case .rem: .remSleep
    case .core: .coreSleep
    case .deep: .deepSleep
    }
  }

  var name: String {
    switch self {
    case .awake: String(localized: "Awake", comment: "Display name for apple sleep stage")
    case .rem: String(localized: "REM", comment: "Display name for apple sleep stage")
    case .core: String(localized: "Core", comment: "Display name for apple sleep stage")
    case .deep: String(localized: "Deep", comment: "Display name for apple sleep stage")
    }
  }

  init?(from category: HKCategoryValueSleepAnalysis) {
    switch category {
    case .awake: self = .awake
    case .asleepREM: self = .rem
    case .asleepCore: self = .core
    case .asleepDeep: self = .deep
    default: return nil
    }
  }
}

struct AppleSleepSegment: Identifiable {
  let id = UUID()
  let stage: AppleSleepStage
  let startDate: Date
  let endDate: Date
}

private extension CGFloat {
  static let tubeWidth: CGFloat = 16
  static let segmentCornerRadius: CGFloat = 5
  static let rowPadding: CGFloat = 8
}

// MARK: - Main View

@MainActor
struct AppleSleepStageChartView: View {
  let sleepAnalysis: SleepAnalysis
  private let preloadedSegments: [AppleSleepSegment]?

  @State private var segments: [AppleSleepSegment] = []
  @State private var timeRange: ClosedRange<Date>?

  init(sleepAnalysis: SleepAnalysis, segments: [AppleSleepSegment]? = nil) {
    self.sleepAnalysis = sleepAnalysis
    self.preloadedSegments = segments
    if let segments, let first = segments.first, let last = segments.last {
      self._segments = State(initialValue: segments)
      self._timeRange = State(initialValue: first.startDate...last.endDate)
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 8) {
        // Y-axis labels
        yAxisLabels

        // Chart canvas
        if let timeRange, segments.isNotEmpty {
          chartCanvas(timeRange: timeRange)
        } else {
          Rectangle()
            .fill(.clear)
        }
      }

      // X-axis labels
      if let timeRange {
        xAxisLabels(timeRange: timeRange)
      }
    }
    .task {
      await loadSegments()
    }
    .onChange(of: sleepAnalysis) { _, _ in
      Task {
        await loadSegments()
      }
    }
  }
}

// MARK: - Data Loading

private extension AppleSleepStageChartView {

  func loadSegments() async {
    let newSegments: [AppleSleepSegment]

    if let preloadedSegments {
      newSegments = preloadedSegments
    } else {
      let samples = await Task {
        (try? await HealthStoreFetcher.shared.fetchSamples(
          for: HKCategoryType(.sleepAnalysis),
          dateRange: DateRange(sleepAnalysis.startDate, sleepAnalysis.endDate)
        )) ?? []
      }.value

      newSegments = samples.compactMap { sample -> AppleSleepSegment? in
        guard
          let categorySample = sample as? HKCategorySample,
          let category = categorySample.sleepCategory,
          let stage = AppleSleepStage(from: category)
        else { return nil }

        return AppleSleepSegment(
          stage: stage,
          startDate: sample.startDate,
          endDate: sample.endDate
        )
      }.sorted { $0.startDate < $1.startDate }
    }

    await MainActor.run {
      self.segments = newSegments
      if let first = newSegments.first, let last = newSegments.last {
        self.timeRange = first.startDate...last.endDate
      }
    }
  }
}

// MARK: - Y-Axis Labels

private extension AppleSleepStageChartView {

  var yAxisLabels: some View {
    VStack(spacing: 0) {
      ForEach(AppleSleepStage.allCases, id: \.rawValue) { stage in
        Text(stage.name)
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxHeight: .infinity)
      }
    }
    .frame(width: 44)
  }
}

// MARK: - X-Axis Labels

private extension AppleSleepStageChartView {

  func xAxisLabels(timeRange: ClosedRange<Date>) -> some View {
    HStack {
      Spacer().frame(width: 52) // Offset for Y-axis

      GeometryReader { geometry in
        let hours = hourMarks(for: timeRange)
        ForEach(hours, id: \.self) { hour in
          let x = xPosition(for: hour, in: geometry.size.width, timeRange: timeRange)
          Text(hour, format: .dateTime.hour())
            .font(.caption2)
            .foregroundStyle(.secondary)
            .position(x: x, y: 10)
        }
      }
    }
    .frame(height: 20)
  }

  func hourMarks(for timeRange: ClosedRange<Date>) -> [Date] {
    var marks: [Date] = []
    let calendar = Calendar.current
    var current = calendar.nextDate(
      after: timeRange.lowerBound,
      matching: DateComponents(minute: 0),
      matchingPolicy: .nextTime
    ) ?? timeRange.lowerBound

    while current <= timeRange.upperBound {
      marks.append(current)
      current = calendar.date(byAdding: .hour, value: 1, to: current) ?? current
    }
    return marks
  }
}

// MARK: - Chart Canvas

private extension AppleSleepStageChartView {

  func chartCanvas(timeRange: ClosedRange<Date>) -> some View {
    Canvas { context, size in
      let rowHeight = size.height / CGFloat(AppleSleepStage.allCases.count)
      let connectionWidth: CGFloat = 5

      // FIRST: Build unified background path and fill with vertical gradient
      var backgroundPath = Path()

      // Add segment backgrounds to path
      for segment in segments {
        let xStart = xPosition(for: segment.startDate, in: size.width, timeRange: timeRange)
        let xEnd = xPosition(for: segment.endDate, in: size.width, timeRange: timeRange)
        let y = yPosition(for: segment.stage, rowHeight: rowHeight)

        let width = max(xEnd - xStart, 1) + connectionWidth
        let height: CGFloat = .tubeWidth * 2 + connectionWidth
        let cornerRadius: CGFloat = .segmentCornerRadius + connectionWidth / 2

        let rect = CGRect(
          x: xStart - connectionWidth / 2,
          y: y - .tubeWidth - connectionWidth / 2,
          width: width,
          height: height
        )
        backgroundPath.addPath(RoundedRectangle(cornerRadius: cornerRadius).path(in: rect))
      }

      // Add vertical connections to path
      for (index, segment) in segments.enumerated() {
        if index < segments.count - 1 {
          let nextSegment = segments[index + 1]
          if segment.stage != nextSegment.stage {
            let xEnd = xPosition(for: segment.endDate, in: size.width, timeRange: timeRange)
            let fromY = yPosition(for: segment.stage, rowHeight: rowHeight)
            let toY = yPosition(for: nextSegment.stage, rowHeight: rowHeight)

            let minY = min(fromY, toY)
            let maxY = max(fromY, toY)
            let cornerRadius: CGFloat = .segmentCornerRadius + connectionWidth / 2

            let rect = CGRect(
              x: xEnd - connectionWidth / 2,
              y: minY,
              width: connectionWidth,
              height: maxY - minY
            )
            backgroundPath.addPath(RoundedRectangle(cornerRadius: cornerRadius).path(in: rect))
          }
        }
      }

      // Create vertical gradient with stops for each stage
      let gradientStops = createStageGradientStops(rowHeight: rowHeight, totalHeight: size.height)
      let gradient = Gradient(stops: gradientStops)

      context.fill(
        backgroundPath,
        with: .linearGradient(
          gradient,
          startPoint: CGPoint(x: 0, y: 0),
          endPoint: CGPoint(x: 0, y: size.height)
        )
      )

      // SECOND: Draw all segments (on top)
      for segment in segments {
        let xStart = xPosition(for: segment.startDate, in: size.width, timeRange: timeRange)
        let xEnd = xPosition(for: segment.endDate, in: size.width, timeRange: timeRange)
        let y = yPosition(for: segment.stage, rowHeight: rowHeight)

        drawSegment(
          context: context,
          xStart: xStart,
          xEnd: xEnd,
          y: y,
          color: segment.stage.color
        )
      }
    }
  }

  func createStageGradientStops(rowHeight: CGFloat, totalHeight: CGFloat) -> [Gradient.Stop] {
    var stops: [Gradient.Stop] = []

    // Leave padding at top and bottom (must match yPosition calculation)
    let connectionWidth: CGFloat = 5
    let verticalPadding = .tubeWidth + connectionWidth / 2
    let usableHeight = totalHeight - verticalPadding * 2
    let stageSpacing = usableHeight / CGFloat(AppleSleepStage.allCases.count - 1)

    for stage in AppleSleepStage.allCases {
      let centerY = verticalPadding + CGFloat(stage.rawValue) * stageSpacing
      let color = stage.color.opacity(0.3)

      // Add stop at center of each row
      let location = min(max(centerY / totalHeight, 0), 1) // Clamp to valid range
      stops.append(Gradient.Stop(color: color, location: location))
    }

    return stops
  }

  func xPosition(for date: Date, in width: CGFloat, timeRange: ClosedRange<Date>) -> CGFloat {
    let connectionWidth: CGFloat = 5
    let totalSeconds = timeRange.upperBound.timeIntervalSince(timeRange.lowerBound)
    let dateSeconds = date.timeIntervalSince(timeRange.lowerBound)
    // Add padding at leading/trailing edges
    let availableWidth = width - connectionWidth
    return connectionWidth / 2 + (dateSeconds / totalSeconds) * availableWidth
  }

  func yPosition(for stage: AppleSleepStage, rowHeight: CGFloat) -> CGFloat {
    let totalHeight = rowHeight * CGFloat(AppleSleepStage.allCases.count)
    // Leave padding at top and bottom to account for tube height + background extension
    let connectionWidth: CGFloat = 5
    let verticalPadding = .tubeWidth + connectionWidth / 2
    let usableHeight = totalHeight - verticalPadding * 2

    // Distribute 4 stages evenly in usable height (3 gaps for 4 stages)
    let stageSpacing = usableHeight / CGFloat(AppleSleepStage.allCases.count - 1)
    return verticalPadding + CGFloat(stage.rawValue) * stageSpacing
  }

  func drawSegment(
    context: GraphicsContext,
    xStart: CGFloat,
    xEnd: CGFloat,
    y: CGFloat,
    color: Color
  ) {
    let width = max(xEnd - xStart, 1)
    let rect = CGRect(
      x: xStart,
      y: y - .tubeWidth,
      width: width,
      height: .tubeWidth * 2
    )
    // Use rounded rectangle for consistent appearance
    let path = RoundedRectangle(cornerRadius: .segmentCornerRadius).path(in: rect)
    context.fill(path, with: .color(color))
  }

}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    AppleSleepStageChartView(sleepAnalysis: SleepAnalysis.previewData[0])
      .frame(height: 250)
      .cardContainer()
  }
}
