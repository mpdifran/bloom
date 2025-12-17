//
//  YearInBloomView.swift
//  Bloom
//
//  Created by Claude on 2025-12-12.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth
import AppUI
import BloomUI

struct YearInBloomView: View {
  let year: Int
  let gradientColors: [Color]

  @State private var viewModel: YearInBloomViewModel

  init(
    year: Int,
    gradientColors: [Color]
  ) {
    self.year = year
    self.gradientColors = gradientColors
    self._viewModel = State(initialValue: YearInBloomViewModel(year: year))
  }

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoading {
          loadingView
        } else if let stats = viewModel.stats {
          contentView(stats: stats)
        } else {
          noDataView
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .background { backgroundView }
      .toolbar {
        ToolbarItem(placement: .principal) {
          VStack {
            Text(viewModel.formattedYear)
              .bold()
              .font(.title3)
              .fontDesign(.rounded)
            Text("Year In Bloom")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.default, value: viewModel.isLoading)
    .task {
      await viewModel.loadStats()
    }
  }
}

// MARK: - Content View

private extension YearInBloomView {

  var backgroundView: some View {
    TimelineView(.animation) { timeline in
      let seconds = timeline.date.timeIntervalSinceReferenceDate
      let rotation = seconds.truncatingRemainder(dividingBy: 20) * 18 // 20 sec per full rotation

      backgroundGradient
        .aspectRatio(1, contentMode: .fill)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(1.1)
    }
    .overlay {
      Rectangle()
        .fill(.thinMaterial)
    }
    .ignoresSafeArea()
  }

  var backgroundGradient: MeshGradient {
    MeshGradient(
      width: 3,
      height: 3,
      points: [
        // Offset points for organic feel
        [0.0, 0.0], [0.3, 0.0], [1.0, 0.0],
        [0.0, 0.6], [0.6, 0.3], [1.0, 0.4],
        [0.0, 1.0], [0.75, 1.0], [1.0, 1.0]
      ],
      colors: [
        gradientColors[0],
        gradientColors[1 % gradientColors.count].opacity(0.4),
        .clear,
        .clear,
        gradientColors[2 % gradientColors.count].opacity(0.5),
        gradientColors[1 % gradientColors.count],
        .clear,
        gradientColors[2 % gradientColors.count].opacity(0.3),
        .clear
      ]
    )
  }

  func contentView(stats: YearInBloomWorkoutStats) -> some View {
    ScrollView {
      VStack(spacing: 20) {
        YearInBloomExerciseEffectivenessCard(stats: stats)
        YearInBloomWalkingRunningDistanceCard(stats: stats)
        YearInBloomCardioFitnessCard(stats: stats)

        if let sleepStats = viewModel.sleepStats {
          YearInBloomSleepStagesCard(stats: sleepStats)
        }

        if let menstrualStats = viewModel.menstrualStats {
          YearInBloomMenstrualCycleCard(stats: menstrualStats)
        }

        if let heartHealthStats = viewModel.heartHealthStats {
          YearInBloomHeartHealthCard(stats: heartHealthStats)
        }
      }
      .padding()
    }
  }
}

// MARK: - Loading View

private extension YearInBloomView {

  var loadingView: some View {
    VStack(spacing: 20) {
      Spacer()

      CircularSpinnerView()
        .foregroundStyle(.tint)

      Text("Calculating your Year in Bloom...")
        .font(.headline)
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)

      Text(viewModel.formattedYear)
        .font(.largeTitle)
        .bold()
        .fontDesign(.rounded)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - No Data View

private extension YearInBloomView {

  var noDataView: some View {
    ContentUnavailableView {
      Label("No Workout Data", systemSymbol: .figureRun)
    } description: {
      Text("We couldn't find any workout data for \(viewModel.formattedYear). Start tracking your workouts to see your Year In Bloom!")
    } actions: {
      Button("Try Again") {
        Task {
          await viewModel.forceRefresh()
        }
      }
      .buttonStyle(.bordered)
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    YearInBloomView(
      year: 2024,
      gradientColors: [
        .green,
        .teal,
        .mint
      ]
    )
  }
}
