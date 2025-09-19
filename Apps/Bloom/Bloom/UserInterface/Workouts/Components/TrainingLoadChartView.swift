//
//  TrainingLoadChartView.swift
//  Bloom
//
//  Created by Assistant on 2025-09-12.
//

import SwiftUI
import Charts
import CoreHealth

extension Color {
  var components: (red: Double, green: Double, blue: Double, alpha: Double) {
    #if canImport(UIKit)
    typealias NativeColor = UIColor
    #elseif canImport(AppKit)
    typealias NativeColor = NSColor
    #endif
    
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    
    guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
      return (0, 0, 0, 0)
    }
    
    return (Double(r), Double(g), Double(b), Double(a))
  }
}

struct TrainingLoadChartView: View {
  @State private var trainingLoadSummary: TrainingLoadSummary?
  @State private var isLoading = true

  var body: some View {
    Group {
      if let summary = trainingLoadSummary, hasTrainingLoadData(summary) {
        contentView(summary: summary)
      } else if isLoading {
        loadingView
      } else {
        VStack {
          statusHeader(summary: nil)
          Spacer()
          Text("No Data")
            .font(.title3)
            .bold()
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .horizontallyCentered()
      }
    }
    .frame(height: 160)
    .cardContainer(fill: .mutedIndigo.gradient)
    .task {
      await loadTrainingLoadData()
    }
  }
}

private extension TrainingLoadChartView {

  func statusHeader(summary: TrainingLoadSummary?) -> some View {
    HStack {
      Image(systemSymbol: .gaugeOpenWithLinesNeedle33percent)
        .font(.title3)
        .foregroundStyle(.mutedIndigo)
        .frame(square: 30)
        .padding(6)
        .background {
          RoundedRectangle(cornerRadius: 13)
            .fill(.white)
        }

      VStack(alignment: .leading) {
        Text("Training Load")
          .font(.title3)
          .bold()

        Text("7-DAY vs. 28-DAY LOAD")
          .font(.caption)
      }

      Spacer()

      if let summary {
        VStack(alignment: .trailing) {
          Text(summary.status.rawValue)

          Text(String(format: "%+.0f%%", summary.percentageDifference))
        }
        .font(.title3)
        .bold()
        .foregroundStyle(.white)
      }
    }
    .fontDesign(.rounded)
  }

  private func contentView(summary: TrainingLoadSummary) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      // Status header
      statusHeader(summary: summary)
      
      // Chart
      Chart {
        // 28-day trend line (background line)
        ForEach(summary.twentyEightDayTrend, id: \.date) { point in
          LineMark(
            x: .value("Date", point.date),
            y: .value("28-day Average", point.value),
            series: .value("28-day", "28-day Average")
          )
          .interpolationMethod(.catmullRom)
        }
        .foregroundStyle(.white.opacity(0.5))
        .lineStyle(StrokeStyle(lineWidth: 6))

        // 7-day trend line (primary colored line)
        ForEach(Array(summary.sevenDayTrend.enumerated()), id: \.offset) {
          index,
          point in
          let twentyEightDayValue = index < summary.twentyEightDayTrend.count ? summary.twentyEightDayTrend[index].value : 0
          
          LineMark(
            x: .value("Date", point.date),
            y: .value("7-day Average", point.value),
            series: .value("7-day", "7-day Average")
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.white)
          .lineStyle(StrokeStyle(lineWidth: 6))

          PointMark(
            x: .value("Date", point.date),
            y: .value("7-day Average", point.value)
          )
          .symbol {
            Circle()
              .fill(colorForTrainingLoadDifference(
                sevenDayValue: point.value,
                twentyEightDayValue: twentyEightDayValue,
                summary: summary
              ))
              .strokeBorder(.white, lineWidth: 0.5)
              .frame(width: 6, height: 6)
          }
        }
      }
      .chartYScale(domain: 0...maxYValue(summary: summary))
      .chartXAxis {
        AxisMarks(values: .stride(by: .day, count: 7)) { value in
          AxisGridLine()
          AxisTick()
          AxisValueLabel(format: .dateTime.month(.abbreviated).day())
        }
      }
      .chartYAxis(.hidden)
    }
  }
  
  private var loadingView: some View {
    VStack(alignment: .leading, spacing: 16) {
      statusHeader(summary: nil)

      Spacer()
      ProgressView()
        .foregroundStyle(.white)
        .horizontallyCentered()
      Spacer()
    }
  }
  
  private func loadTrainingLoadData() async {
    // Ensure data is calculated first
    await TrainingLoadCalculator.shared.refreshTrainingLoad()
    
    // Now get the summary
    let summary = await TrainingLoadCalculator.shared.trainingLoadSummary
    
    await MainActor.run {
      self.trainingLoadSummary = summary
      self.isLoading = false
    }
  }
  
  private func hasTrainingLoadData(_ summary: TrainingLoadSummary) -> Bool {
    !summary.sevenDayTrend.isEmpty && summary.sevenDayTrend.contains { $0.value > 0 }
  }
  
  private func colorForTrainingLoadDifference(sevenDayValue: Double, twentyEightDayValue: Double, summary: TrainingLoadSummary) -> Color {
    let difference = abs(sevenDayValue - twentyEightDayValue)
    
    // Calculate maximum possible difference in the dataset for scaling
    let allSevenDayValues = summary.sevenDayTrend.map(\.value)
    let allTwentyEightDayValues = summary.twentyEightDayTrend.map(\.value)
    
    let maxSevenDay = allSevenDayValues.max() ?? 0
    let minSevenDay = allSevenDayValues.min() ?? 0
    let maxTwentyEightDay = allTwentyEightDayValues.max() ?? 0
    let minTwentyEightDay = allTwentyEightDayValues.min() ?? 0
    
    // Estimate maximum reasonable difference for normalization
    let maxPossibleDifference = max(abs(maxSevenDay - minTwentyEightDay), abs(minSevenDay - maxTwentyEightDay))
    
    // Calculate ratio (0.0 = no difference, 1.0 = maximum difference)
    let ratio = maxPossibleDifference > 0 ? min(difference / maxPossibleDifference, 1.0) : 0.0
    
    // Interpolate between blue (close to 28-day line) and pink (far from 28-day line)
    let blue = Color.blue
    let pink = Color.pink
    
    return Color(
      red: blue.components.red + (pink.components.red - blue.components.red) * ratio,
      green: blue.components.green + (pink.components.green - blue.components.green) * ratio,
      blue: blue.components.blue + (pink.components.blue - blue.components.blue) * ratio
    )
  }
  
  private func maxYValue(summary: TrainingLoadSummary) -> Double {
    let allValues = summary.sevenDayTrend.map(\.value) +
                   summary.twentyEightDayTrend.map(\.value)
    let maxValue = allValues.max() ?? 100
    return maxValue * 1.1 // Add 10% padding
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      TrainingLoadChartView()
    }
  }
}
