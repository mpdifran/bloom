//
//  HeartRateZoneStatusView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-07.
//

import SwiftUI
import CoreHealth

private extension CGFloat {
  static let zoneBarHeight: CGFloat = 20
  static let zoneBarMinWidth: CGFloat = 25
  static let indicatorInset: CGFloat = 2
  static let indicatorWidth: CGFloat = 6
  static let containerPadding: CGFloat = 4

  func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
    Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
  }
}

struct HeartRateZoneStatusView: View {
  let heartRate: Double
  let zones: HeartRateZones?

  @Environment(\.isLuminanceReduced) private var isLuminanceReduced

  var body: some View {
    VStack {
      if currentZone > 0 {
        zoneBarView
      } else if let _ = zones {
        warmUpView
      } else {
        noZonesView
      }
      heartRateView
    }
    .frame(maxWidth: .infinity)
    .padding(.containerPadding)
//    .background {
//      RoundedRectangle(cornerRadius: containerCornerRadius)
//        .fill(zoneColor)
//    }
    .animation(.default, value: heartRate)
  }
}

private extension HeartRateZoneStatusView {

  var warmUpView: some View {
    Text("Warming Up")
      .font(.caption)
      .fontWeight(.bold)
      .fontDesign(.rounded)
  }

  var noZonesView: some View {
    Text("No Heart Zones Set")
      .font(.caption)
      .fontWeight(.bold)
      .fontDesign(.rounded)
      .foregroundStyle(.secondary)
  }

  var zoneBarView: some View {
    HStack(spacing: 2) {
      ForEach(1...5, id: \.self) { zone in
        let isCurrentZone = zone == currentZone

        RoundedRectangle(cornerRadius: zoneCornerRadius)
          .fill(color(for: zone))
          .opacity(isCurrentZone ? 1 : 0.5)
          .frame(width: isCurrentZone ? nil : .zoneBarMinWidth, height: .zoneBarHeight)
          .frame(maxWidth: isCurrentZone ? .infinity : nil)
          .overlay {
            if isCurrentZone {
              GeometryReader { geometry in
                Capsule()
                  .fill(.black)
                  .frame(width: .indicatorWidth, height: .zoneBarHeight - .indicatorInset * 2)
                  .position(
                    x: dotXPosition(in: geometry.size.width),
                    y: geometry.size.height / 2
                  )
              }
            }
          }
      }
    }
  }

  var zoneCornerRadius: CGFloat {
    (CGFloat.indicatorWidth / 2) + CGFloat.indicatorInset
  }

  var containerCornerRadius: CGFloat {
    zoneCornerRadius + .containerPadding
  }

  var beatInterval: TimeInterval {
    // Guard against heartRate == 0 (before the first sample lands) — 60.0/0 is +Infinity,
    // which feeds an infinite truncatingRemainder divisor and animation duration into the
    // TimelineView every 0.05s.
    heartRate > 0 ? 60.0 / heartRate : 1.0
  }

  var heartRateView: some View {
    HStack {
      if isLuminanceReduced {
        Image(systemSymbol: .heartFill)
          .font(.caption2)
          .foregroundStyle(heartIconColor)
      } else {
        TimelineView(PeriodicTimelineSchedule(from: .now, by: 0.05)) { timeline in
          let phase = timeline.date.timeIntervalSince1970.truncatingRemainder(dividingBy: beatInterval)
          let isBeat = phase < beatInterval * 0.15

          Image(systemSymbol: .heartFill)
            .font(.caption2)
            .foregroundStyle(heartIconColor)
            .scaleEffect(isBeat ? 1.5 : 1.0)
            .animation(.linear(duration: beatInterval / 2), value: isBeat)
        }
      }

      HStack(alignment: .firstTextBaseline) {
        Text(heartRate.format(using: .noDecimalPlaces))
          .contentTransition(.numericText(value: heartRate))

        Text("BPM")

        Text(verbatim: "•")

        Text("Zone \(currentZone)")
          .contentTransition(.numericText(value: Double(currentZone)))
      }
      .foregroundStyle(color(for: currentZone))
    }
    .font(.subheadline)
    .fontWeight(.semibold)
    .fontDesign(.rounded)
    .monospacedDigit()
  }

  var heartIconColor: Color {
    switch currentZone {
    case 1:
        .heartRateZone1
    case 2:
        .heartRateZone2
    case 3:
        .heartRateZone3
    case 4:
        .heartRateZone4
    case 5:
        .heartRateZone5
    default:
        .mutedRed
    }
  }

  var zoneColor: Color {
    color(for: currentZone)
  }

  func color(for zone: Int) -> Color {
    switch zone {
    case 1:
        .heartRateZone1
    case 2:
        .heartRateZone2
    case 3:
        .heartRateZone3
    case 4:
        .heartRateZone4
    case 5:
        .heartRateZone5
    default:
        .white
    }
  }

  var zoneProgress: CGFloat {
    guard let zones else { return 0.5 }

    let (lower, upper): (Double, Double) = switch currentZone {
    case 1: (zones.zone1, zones.zone2 - 1)
    case 2: (zones.zone2, zones.zone3 - 1)
    case 3: (zones.zone3, zones.zone4 - 1)
    case 4: (zones.zone4, zones.zone5 - 1)
    case 5: (zones.zone5, zones.maxHeartRate)
    default: (0, 1)
    }

    guard upper > lower else { return 0.5 }
    return CGFloat((heartRate - lower) / (upper - lower)).clamped(to: 0...1)
  }

  func dotXPosition(in width: CGFloat) -> CGFloat {
    let indicatorRadius: CGFloat = .indicatorWidth / 2
    let minX = indicatorRadius + .indicatorInset
    let maxX = width - indicatorRadius - .indicatorInset
    return minX + ((maxX - minX) * zoneProgress)
  }
}

private extension HeartRateZoneStatusView {

  var currentZone: Int {
    guard let zones else { return 0 }

    if heartRate < zones.zone1 { return 0 }
    else if heartRate < zones.zone2 { return 1 }
    else if heartRate < zones.zone3 { return 2 }
    else if heartRate < zones.zone4 { return 3 }
    else if heartRate < zones.zone5 { return 4 }
    else { return 5 }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      HeartRateZoneStatusView(
        heartRate: 60,
        zones: nil
      )

      HeartRateZoneStatusView(
        heartRate: 60,
        zones: HeartRateZones(
          heartRateReserve: 125,
          restingHeartRate: 60,
          maxHeartRate: 185,
          zone1: 110,
          zone2: 125,
          zone3: 140,
          zone4: 155,
          zone5: 170
        )
      )

      HeartRateZoneStatusView(
        heartRate: 113,
        zones: HeartRateZones(
          heartRateReserve: 125,
          restingHeartRate: 60,
          maxHeartRate: 185,
          zone1: 110,
          zone2: 125,
          zone3: 140,
          zone4: 155,
          zone5: 170
        )
      )

      HeartRateZoneStatusView(
        heartRate: 143,
        zones: HeartRateZones(
          heartRateReserve: 125,
          restingHeartRate: 60,
          maxHeartRate: 185,
          zone1: 110,
          zone2: 125,
          zone3: 140,
          zone4: 155,
          zone5: 170
        )
      )

      HeartRateZoneStatusView(
        heartRate: 170,
        zones: HeartRateZones(
          heartRateReserve: 125,
          restingHeartRate: 60,
          maxHeartRate: 185,
          zone1: 110,
          zone2: 125,
          zone3: 140,
          zone4: 155,
          zone5: 170
        )
      )
    }
  }
}

#Preview("Random HR") {
  @Previewable @State var heartRate: Double = 120

  let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

  PreviewEnvironment {
    HeartRateZoneStatusView(
      heartRate: heartRate,
      zones: HeartRateZones(
        heartRateReserve: 125,
        restingHeartRate: 60,
        maxHeartRate: 185,
        zone1: 110,
        zone2: 125,
        zone3: 140,
        zone4: 155,
        zone5: 170
      )
    )
    .onReceive(timer) { _ in
      heartRate = Double.random(in: 60...185)
    }
  }
}
