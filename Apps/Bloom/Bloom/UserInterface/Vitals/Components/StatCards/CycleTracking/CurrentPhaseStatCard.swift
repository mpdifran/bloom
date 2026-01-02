//
//  CurrentPhaseStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct CurrentPhaseStatCard: View {
  let summary: MenstrualSummary?

  private var phase: MenstrualCyclePhase? {
    guard let phase = summary?.currentPhase(), phase != .unknown else { return nil }
    return phase
  }

  private var cycleDuration: Int {
    summary?.averageCycleDuration ?? 28
  }

  private var menstruationDuration: Int {
    summary?.averageMenstruationDays ?? 3
  }

  private var ovulationDay: Int {
    cycleDuration / 2
  }

  private var phaseDurations: [(phase: MenstrualCyclePhase, duration: Int)] {
    let follicularDuration = max(ovulationDay - 2 - menstruationDuration, 1)
    let ovulationDuration = 3
    let lutealDuration = max(cycleDuration - ovulationDay - 1, 1)

    return [
      (.menstrual, menstruationDuration),
      (.follicular, follicularDuration),
      (.ovulation, ovulationDuration),
      (.luteal, lutealDuration)
    ]
  }

  private var currentDayInCycle: Int? {
    guard let summary, let latestCycle = summary.mostRecentCycle else { return nil }
    let days = Calendar.current.dateComponents([.day], from: latestCycle.startDate, to: .now).day ?? 0
    return days + 1
  }

  var body: some View {
    if let phase {
      StatCard(
        symbol: .circleDottedAndCircle,
        title: "Current Phase",
        value: phase.name,
        valueStyle: .largeTinted(nil),
        aspectRatio: 2
      ) {
        phaseTimeline
      }
      .tint(phase.color ?? .pink)
    } else {
      StatCard(
        symbol: .circleDottedAndCircle,
        title: "Current Phase",
        value: "No Data",
        valueStyle: .largeTinted(nil),
        aspectRatio: 2
      )
      .tint(.gray)
    }
  }

  @ViewBuilder
  private var phaseTimeline: some View {
    VStack {
      Spacer()
      GeometryReader { geometry in
        let totalDuration = phaseDurations.reduce(0) { $0 + $1.duration }

        ZStack(alignment: .leading) {
          HStack(spacing: 2) {
            ForEach(phaseDurations, id: \.phase) { item in
              let width = (CGFloat(item.duration) / CGFloat(totalDuration)) * (geometry.size.width - CGFloat(phaseDurations.count - 1) * 2)

              Capsule()
                .fill(item.phase.color ?? .gray)
                .frame(width: width, height: 16)
            }
          }

          if let day = currentDayInCycle, day <= cycleDuration {
            let position = calculateDotPosition(day: day, totalWidth: geometry.size.width)

            Circle()
              .fill(.white)
              .frame(width: 12, height: 12)
              .shadow(radius: 2)
              .offset(x: position - 6)
          }
        }
      }
      .frame(height: 20)
      Spacer()
    }
  }

  private func calculateDotPosition(day: Int, totalWidth: CGFloat) -> CGFloat {
    let totalDuration = phaseDurations.reduce(0) { $0 + $1.duration }
    let spacing: CGFloat = 2
    let totalSpacing = CGFloat(phaseDurations.count - 1) * spacing
    let usableWidth = totalWidth - totalSpacing
    let endCapInset: CGFloat = 2 // (capsuleHeight - dotDiameter) / 2 = (16 - 12) / 2

    var accumulatedDays = 0
    var accumulatedWidth: CGFloat = 0

    for (index, item) in phaseDurations.enumerated() {
      let phaseWidth = (CGFloat(item.duration) / CGFloat(totalDuration)) * usableWidth
      let insetWidth = phaseWidth - (endCapInset * 2)

      if day <= accumulatedDays + item.duration {
        let dayWithinPhase = day - accumulatedDays
        let positionWithinPhase = (CGFloat(dayWithinPhase) - 0.5) / CGFloat(item.duration) * insetWidth
        return accumulatedWidth + endCapInset + positionWithinPhase
      }

      accumulatedDays += item.duration
      accumulatedWidth += phaseWidth + (index < phaseDurations.count - 1 ? spacing : 0)
    }

    return totalWidth
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      CurrentPhaseStatCard(summary: previewMenstrualPhase)
      CurrentPhaseStatCard(summary: previewFollicularPhase)

      CurrentPhaseStatCard(summary: previewOvulationPhase)
      CurrentPhaseStatCard(summary: previewLutealPhase)

      CurrentPhaseStatCard(summary: nil)
    }
  }
}

// Menstrual phase: day 1-3 (cycles must be ordered oldest to newest for averageCycleDuration)
private let previewMenstrualPhase: MenstrualSummary = {
  let calendar = Calendar.current
  let now = Date()
  let cycles = [
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -30, to: now)!, samples: []),
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -2, to: now)!, samples: [])
  ]
  return MenstrualSummary(menstrualCycles: cycles)
}()

// Follicular phase: day 6-12
private let previewFollicularPhase: MenstrualSummary = {
  let calendar = Calendar.current
  let now = Date()
  let cycles = [
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -36, to: now)!, samples: []),
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -8, to: now)!, samples: [])
  ]
  return MenstrualSummary(menstrualCycles: cycles)
}()

// Ovulation phase: day 13-15
private let previewOvulationPhase: MenstrualSummary = {
  let calendar = Calendar.current
  let now = Date()
  let cycles = [
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -42, to: now)!, samples: []),
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -14, to: now)!, samples: [])
  ]
  return MenstrualSummary(menstrualCycles: cycles)
}()

// Luteal phase: day 16-28
private let previewLutealPhase: MenstrualSummary = {
  let calendar = Calendar.current
  let now = Date()
  let cycles = [
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -48, to: now)!, samples: []),
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -20, to: now)!, samples: [])
  ]
  return MenstrualSummary(menstrualCycles: cycles)
}()
