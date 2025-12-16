//
//  YearInBloomExerciseEffectivenessCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-15.
//

import SwiftUI
import Charts
import CoreHealth
import HealthKit
import SFSafeSymbols

struct YearInBloomExerciseEffectivenessCard: View {
  let stats: YearInBloomWorkoutStats

  @State private var selectedMonth: MonthlyZoneMinutesData?
  @State private var selectedWorkoutType: WorkoutTypeStats?
  @State private var showAllWorkoutTypes = false

  var body: some View {
    YearInBloomCard(
      title: "Exercise Effectiveness",
      focusStat: totalScaledZoneMinutes.formatted(),
      focusStatLabel: "Zone Minutes",
      foregroundFill: .black,
      backgroundFill: .mutedPink) {
        zoneMinutesChart
        legendView
        workoutTypesSection
      }
  }
}

// MARK: - Chart

private extension YearInBloomExerciseEffectivenessCard {

  var zoneMinutesChart: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(selectedWorkoutType?.activityName ?? "All Workouts")
        .font(.caption)
        .foregroundStyle(.black.secondary)
        .contentTransition(.numericText())

      Chart {
        ForEach(filteredMonthlyData) { month in
          // Zone 1 (bottom)
          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone1)
          )
          .foregroundStyle(.black.opacity(0.2))

          // Zone 2
          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone2)
          )
          .foregroundStyle(.black.opacity(0.4))

          // Zone 3 (already scaled ×2)
          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone3)
          )
          .foregroundStyle(.black.opacity(0.55))

          // Zone 4 (already scaled ×2)
          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone4)
          )
          .foregroundStyle(.black.opacity(0.65))

          // Zone 5 (already scaled ×3, top)
          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone5)
          )
          .foregroundStyle(.black)

          // Star for high-performing months
          if month.total >= 600 {
            PointMark(
              x: .value("Month", month.date, unit: .month),
              y: .value("Minutes", month.total)
            )
            .symbol {
              Image(systemSymbol: .starFill)
                .font(.system(size: 8))
                .foregroundStyle(.black)
            }
            .offset(y: -12)
          }
        }
      }
      .chartXAxis {
        AxisMarks(values: .stride(by: .month)) { _ in
          AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
            .foregroundStyle(.black)
        }
      }
      .chartYAxis(.hidden)
      .chartLegend(.hidden)
      .chartOverlay { proxy in
        GeometryReader { geometry in
          Rectangle()
            .fill(.clear)
            .contentShape(Rectangle())
            .gesture(
              DragGesture(minimumDistance: 0)
                .onChanged { value in
                  let xPosition = value.location.x
                  if let date: Date = proxy.value(atX: xPosition) {
                    selectedMonth = findNearestMonth(to: date)
                  }
                }
                .onEnded { _ in
                  selectedMonth = nil
                }
            )

          // Annotation overlay
          if let selected = selectedMonth,
             let xPosition = proxy.position(forX: selected.date) {
            Text("\(Int(selected.total)) min")
              .font(.caption)
              .fontWeight(.semibold)
              .fontDesign(.rounded)
              .padding(.horizontal, 12)
              .padding(.vertical, 4)
              .background(.regularMaterial, in: Capsule())
              .position(x: xPosition, y: 0)
              .environment(\.colorScheme, .dark)
          }
        }
      }
      .frame(height: 140)
    }
  }

  var workoutTypesSection: some View {
    let columns = [
      GridItem(.flexible()),
      GridItem(.flexible())
    ]
    let displayedWorkoutTypes = showAllWorkoutTypes
      ? stats.topWorkoutTypes
      : Array(stats.topWorkoutTypes.prefix(6))

    return VStack(spacing: 8) {
      LazyVGrid(columns: columns, spacing: 0) {
        ForEach(displayedWorkoutTypes) { workoutType in
          let isSelected = selectedWorkoutType?.id == workoutType.id

          HStack {
            Image(systemName: workoutType.activityType.systemImage)
              .frame(width: 24)
            Text("×\(workoutType.count)")
            Spacer(minLength: 0)
            Text("\(Int(workoutType.scaledZoneMinutes)) min")
          }
          .font(.subheadline)
          .fontDesign(.rounded)
          .bold()
          .foregroundStyle(.black)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(isSelected ? .black.opacity(0.2) : .clear, in: Capsule())
          .contentShape(Rectangle())
          .animation(.default, value: selectedWorkoutType)
          .sensoryFeedback(.selection, trigger: selectedWorkoutType)
          .onTapGesture {
            withAnimation {
              if selectedWorkoutType?.id == workoutType.id {
                selectedWorkoutType = nil
              } else {
                selectedWorkoutType = workoutType
              }
            }
          }
        }
      }

      if stats.topWorkoutTypes.count > 6 {
        Button {
          showAllWorkoutTypes.toggle()
        } label: {
          Text(showAllWorkoutTypes ? "Show Less" : "Show More")
            .font(.caption)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(.black)
            .padding(.vertical, 4)
            .padding(.horizontal, 16)
            .background(.black.opacity(0.2), in: Capsule())
        }
        .buttonStyle(.plain)
        .tint(.black)
      }
    }
    .padding(.top, 8)
    .animation(.default, value: showAllWorkoutTypes)
  }

  func findNearestMonth(to date: Date) -> MonthlyZoneMinutesData? {
    let calendar = Calendar.current
    let targetMonth = calendar.component(.month, from: date)
    return filteredMonthlyData.first { data in
      calendar.component(.month, from: data.date) == targetMonth
    }
  }

  var legendView: some View {
    HStack(spacing: 12) {
      zoneLegendItem(color: .black.opacity(0.2), label: "Zone 1")
      zoneLegendItem(color: .black.opacity(0.4), label: "Zone 2")
      zoneLegendItem(color: .black.opacity(0.55), label: "Zone 3")
      zoneLegendItem(color: .black.opacity(0.65), label: "Zone 4")
      zoneLegendItem(color: .black, label: "Zone 5")
      Spacer()
    }
    .font(.caption2)
    .fontDesign(.rounded)
  }

  func zoneLegendItem(color: Color, label: String) -> some View {
    HStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      Text(label)
        .foregroundStyle(.black)
    }
  }
}

private extension YearInBloomExerciseEffectivenessCard {

  var totalScaledZoneMinutes: Int {
    Int(stats.yearTotals.totalZoneMinutes?.scaledZoneMinutes ?? 0)
  }

  var monthlyData: [MonthlyZoneMinutesData] {
    stats.monthlyScaledZoneMinutes()
  }

  var filteredMonthlyData: [MonthlyZoneMinutesData] {
    if let selected = selectedWorkoutType {
      return stats.monthlyScaledZoneMinutes(for: selected)
    }
    return stats.monthlyScaledZoneMinutes()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomExerciseEffectivenessCard(
        stats: .preview
      )
    }
  }
}
