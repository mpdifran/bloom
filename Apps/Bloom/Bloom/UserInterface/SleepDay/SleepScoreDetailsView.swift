//
//  SleepScoreDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-15.
//

import SFSafeSymbols
import SwiftUI
import CoreHealth

struct SleepScoreDetailsView: View {
  let sleepAnalysis: SleepAnalysis

  var body: some View {
    VStack {
      HStack {
        LabelledText(
          label: "Length",
          symbol: .clock,
          value: "\(DateFormatter.timeIntervalHourMinuteAbbreviated.string(for: sleepAnalysis.overallDurationComponents) ?? "")"
        )
        .tint(.mutedGreen)

        LabelledText(
          label: "Awake",
          symbol: .boltHorizontal,
          value: awakeDescription
        )
        .tint(sleepAnalysis.awakeSleepHours == nil ? .gray : .awakeSleep)

        LabelledText(
          label: "HR",
          symbol: .heart,
          value: heartRateDescription
        )
        .tint(sleepAnalysis.averageHeartRate == nil ? .gray : .mutedPink)
      }

      HStack {
        LabelledText(
          label: "REM",
          symbol: .eyes,
          value: remDescription
        )
        .tint(sleepAnalysis.remSleepHours == nil ? Color.gray : Color.remSleep)
        
        LabelledText(
          label: "Core",
          symbol: .circleDottedCircle,
          value: coreDescription
        )
        .tint(sleepAnalysis.coreSleepHours == nil ? .gray : .coreSleep)

        LabelledText(
          label: "Deep",
          symbol: .arrowDownToLine,
          value: deepDescription
        )
        .tint(sleepAnalysis.deepSleepHours == nil ? .gray : .deepSleep.lighter())
      }
    }
    .animation(.default, value: sleepAnalysis)
  }
}

extension SleepScoreDetailsView {

  var remDescription: String {
    if let remComponents = sleepAnalysis.remSleepComponents, let value = DateFormatter.timeIntervalHourMinuteAbbreviated.string(from: remComponents) {
      return value
    }
    return "--"
  }

  var coreDescription: String {
    if let coreComponents = sleepAnalysis.coreSleepComponents, let value = DateFormatter.timeIntervalHourMinuteAbbreviated.string(from: coreComponents) {
      return value
    }
    return "--"
  }

  var deepDescription: String {
    if let deepComponents = sleepAnalysis.deepSleepComponents, let value = DateFormatter.timeIntervalHourMinuteAbbreviated.string(from: deepComponents) {
      return value
    }
    return "--"
  }

  var awakeDescription: String {
    if let awakeComponents = sleepAnalysis.awakeSleepComponents, let value = DateFormatter.timeIntervalHourMinuteAbbreviated.string(from: awakeComponents) {
      return value
    }
    return "--"
  }

  var heartRateDescription: String {
    if let heartRate = sleepAnalysis.averageHeartRate {
      return "\(heartRate.format()) bpm"
    } else {
      return "--"
    }
  }
}

private struct LabelledText: View {
  let label: String
  let symbol: SFSymbol
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 0) {
        Text(label)

        Spacer()

        Image(systemSymbol: symbol)
      }
      .font(.caption)
      .bold()
      .foregroundStyle(.tint)

      Text(value)
        .foregroundStyle(.tint)
        .bold()
        .font(.title3)
        .fontDesign(.rounded)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .contentTransition(.numericText())
    }
    .horizontalAlignment(.leading)
    .frame(maxWidth: .infinity)
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      SleepScoreDetailsView(sleepAnalysis: SleepAnalysis.previewData[0])

      SleepScoreDetailsView(
        sleepAnalysis: SleepAnalysis(
          startDate: .now.addingTimeInterval(-30000),
          endDate: .now,
          hasDetailedSleepCategories: false,
          deepSleepMinutes: 0,
          coreSleepMinutes: 0,
          remSleepMinutes: 0,
          awakeSleepMinutes: 0,
          averageRestingHeartRate: nil,
          environmentalSoundLevels: [],
          heartRate: [],
          respiratoryRate: [],
          wristTemperature: nil
        )
      )
    }
  }
}
