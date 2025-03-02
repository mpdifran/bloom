//
//  BedtimeActivityView.swift
//  DeviceActivityReportExtension
//
//  Created by Mark DiFranco on 2024-06-12.
//

import SwiftUI
import Charts

extension BedtimeActivityView {
  struct Configuration {
    let usage: [UsageInfo]
  }

  struct UsageInfo: Identifiable {
    let id: String
    let name: String
    var duration: TimeInterval
  }
}

struct BedtimeActivityView: View {
  let configuration: Configuration

  var body: some View {
    VStack {
      if sortedUsageInfos.isEmpty {
        HStack {
          Spacer()
          VStack {
            Text("No Device Use Last Night")
              .bold()
            Text("Good job!")
              .font(.caption)
          }
          Spacer()
        }
        .foregroundStyle(.secondary)
      }
      ForEach(sortedUsageInfos.prefix(3)) { usageInfo in
        HStack {
          Text(usageInfo.name)
            .font(.title3)
            .bold()
          Spacer()
          Text("\(DateFormatter.timeIntervalHourMinuteSecondShort.string(from: usageInfo.duration) ?? "0")")
            .foregroundStyle(.tint)
            .font(.title3)
            .bold()
            .fontDesign(.rounded)
        }
        .padding()
        .background {
          RoundedRectangle(cornerRadius: 13)
            .fill(.background.tertiary)
        }
      }

      Spacer(minLength: 0)
    }
  }
}

private extension BedtimeActivityView {

  var sortedUsageInfos: [UsageInfo] {
    configuration.usage.sorted(by: { $0.duration > $1.duration })
  }
}

// In order to support previews for your extension's custom views, make sure its source files are
// members of your app's Xcode target as well as members of your extension's target. You can use
// Xcode's File Inspector to modify a file's Target Membership.
#Preview {
  List {
    BedtimeActivityView(
      configuration: BedtimeActivityView.Configuration(
        usage: [
          BedtimeActivityView.UsageInfo(id: "123", name: "LinkedIn", duration: 342),
          BedtimeActivityView.UsageInfo(id: "456", name: "Instagram", duration: 186),
          BedtimeActivityView.UsageInfo(id: "789", name: "Wealthsimple", duration: 93)
        ]
      )
    )
    BedtimeActivityView(
      configuration: BedtimeActivityView.Configuration(
        usage: []
      )
    )
  }
}
