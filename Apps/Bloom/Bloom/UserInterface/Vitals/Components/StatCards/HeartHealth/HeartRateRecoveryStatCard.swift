//
//  HeartRateRecoveryStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI
import Charts

struct HeartRateRecoveryStatCard: View {
  let data: HeartRateRecoveryData?

  var body: some View {
    StatCard(
      symbol: .arrowDownHeartFill,
      title: "HR Recovery",
      value: hasData ? nil : "No Data",
      valueStyle: .largeTinted(nil),
      layerContent: hasData,
      includePadding: !hasData
    ) {
      barChart
    }
    .tint(data == nil ? .gray : .mutedRed)
  }
}

private extension HeartRateRecoveryStatCard {

  var hasData: Bool {
    data?.thisWeekAverage != nil || data?.lastWeekAverage != nil
  }

  @ViewBuilder
  var barChart: some View {
    if hasData {
      Chart {
        if let lastWeek = data?.lastWeekAverage {
          BarMark(
            x: .value("Week", "Last"),
            y: .value("BPM", lastWeek)
          )
          .foregroundStyle(.gray)
          .cornerRadius(6)
          .annotation(position: .top) {
            Text("\(Int(lastWeek)) bpm")
              .font(.caption)
              .bold()
              .fontDesign(.rounded)
          }
        }

        if let thisWeek = data?.thisWeekAverage {
          BarMark(
            x: .value("Week", "This"),
            y: .value("BPM", thisWeek)
          )
          .foregroundStyle(.mutedRed)
          .cornerRadius(6)
          .annotation(position: .top) {
            Text("\(Int(thisWeek)) bpm")
              .font(.caption)
              .bold()
              .fontDesign(.rounded)
          }
        }
      }
      .chartXAxis(.hidden)
      .chartYAxis(.hidden)
      .chartYScale(domain: 0...(maxValue * 1.2))
    }
  }

  var maxValue: Double {
    max(data?.thisWeekAverage ?? 0, data?.lastWeekAverage ?? 0)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        HeartRateRecoveryStatCard(
          data: HeartRateRecoveryData(thisWeekAverage: 28, lastWeekAverage: 24)
        )
        HeartRateRecoveryStatCard(
          data: HeartRateRecoveryData(thisWeekAverage: 32, lastWeekAverage: nil)
        )
      }

      HStack {
        HeartRateRecoveryStatCard(
          data: HeartRateRecoveryData(thisWeekAverage: nil, lastWeekAverage: 20)
        )
        HeartRateRecoveryStatCard(data: nil)
      }
    }
  }
}
