//
//  CardioFitnessStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols

struct CardioFitnessStoryPage: View, StoryPage {
  let stats: YearInBloomWorkoutStats

  var focusSentence: Text {
    if let level = stats.currentCardioFitnessLevel {
      return Text("Your cardio fitness is ")
        .foregroundStyle(.secondary) +
      Text(level.name)
        .foregroundStyle(level.color) +
      Text(formattedVO2Max)
        .foregroundStyle(.secondary)
    }
    return Text("Track more cardio workouts to see your fitness level")
      .foregroundStyle(.secondary)
  }

  var mainContent: some View {
    VStack(spacing: 20) {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        if let vo2Max = stats.latestVO2Max {
          statCard(label: "VO₂ Max", value: String(format: "%.1f", vo2Max), icon: .heartFill)
        }
        if let change = vo2MaxChange {
          let changeText = change >= 0 ? "+\(String(format: "%.1f", change))" : String(format: "%.1f", change)
          statCard(label: "Year Change", value: changeText, icon: .arrowUpArrowDown)
        }
      }
      .padding(.horizontal, 24)
    }
  }

  private var formattedVO2Max: String {
    guard let vo2Max = stats.latestVO2Max else { return "" }
    return " at \(String(format: "%.1f", vo2Max))"
  }

  private var vo2MaxChange: Double? {
    let values = stats.monthlyVO2Max.compactMap(\.averageVO2Max)
    guard let first = values.first, let last = values.last else { return nil }
    return last - first
  }

  private func statCard(label: String, value: String, icon: SFSymbol) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemSymbol: icon)
        .font(.title2)
        .foregroundStyle(.secondary)

      Text(value)
        .font(.title2)
        .bold()
        .fontDesign(.rounded)

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }
}

#Preview {
  PreviewEnvironment {
    CardioFitnessStoryPage(stats: .preview)
  }
}
