//
//  YearInBloomStoriesView.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth
import AppUI
import BloomUI
import TelemetryDeck

struct YearInBloomStoriesView: View {
  let year: Int

  @Environment(\.dismiss) private var dismiss

  @State private var viewModel: YearInBloomViewModel
  @State private var currentPage = 0
  @State private var progress: CGFloat = 0
  @State private var isPaused = false

  private let pageDuration: TimeInterval = 10.0
  private let tickInterval: TimeInterval = 0.1
  @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

  init(year: Int) {
    self.year = year
    self._viewModel = State(initialValue: YearInBloomViewModel(year: year))
  }

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoading {
          YearInBloomLoadingView(year: year)
        } else {
          storiesContent
        }
      }
      .safeAreaInset(edge: .bottom) {
        if availablePages.isNotEmpty {
          if #available(iOS 26.0, *) {
            Button {
              // TODO: Share image
            } label: {
              Label("Share", systemSymbol: .squareAndArrowUp)
                .bold()
                .foregroundStyle(.text)
                .padding()
            }
            .glassEffect()
            .horizontalAlignment(.trailing)
            .padding()
          } else {
            Button {
              // TODO: Share image
            } label: {
              Label("Share", systemSymbol: .squareAndArrowUp)
            }
            .buttonStyle(.primary)
            .horizontalAlignment(.trailing)
            .padding()
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }

//        if availablePages.isNotEmpty {
//          ToolbarItemGroup(placement: .bottomBar) {
//            Spacer()
//            Button {
//              // TODO: Share image
//            } label: {
//              Label("Share", systemSymbol: .squareAndArrowUp)
//                .foregroundStyle(.text)
//            }
//            .buttonStyle(.plain)
//          }
//        }
      }
      .removeScrollEdgeEffect(shouldHide: true)
      .navigationBarTitleDisplayMode(.inline)
    }
    .overlay {
      StoryProgressBar(
        currentPage: currentPage,
        progress: progress,
        totalPages: totalPages
      )
      .zStackAlignment(.top)
      .padding(.horizontal)
      .padding(.top, -10)
    }
    .background {
      Rectangle()
        .fill(.background)
        .ignoresSafeArea()
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.default, value: viewModel.isLoading)
    .task {
      await viewModel.loadStats()
    }
    .onAppear {
      TelemetryDeck.signal("View Year In Bloom")
    }
  }
}

// MARK: - Stories Content

private extension YearInBloomStoriesView {

  var storiesContent: some View {
    currentPageView
      .id(currentPage)
      .transition(.opacity)
      .animation(.easeInOut(duration: 0.3), value: currentPage)
      .overlay { gestureOverlay }
      .onReceive(timer) { _ in
        guard !isPaused else { return }
        updateProgress()
      }
      .onChange(of: currentPage) { _, _ in
        progress = 0
      }
  }

  var gestureOverlay: some View {
    HStack(spacing: 0) {
      // Left tap area - go back
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture { goToPreviousPage() }

      // Right tap area - go forward
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture { goToNextPage() }
    }
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in isPaused = true }
        .onEnded { _ in isPaused = false }
    )
  }

  var availablePages: [StoryPageType] {
    guard viewModel.stats != nil else { return [] }

    var pages: [StoryPageType] = [.workouts, .exerciseEffectiveness, .distance, .cardioFitness]

    if viewModel.sleepStats != nil { pages.append(.sleep) }
    if viewModel.menstrualStats != nil { pages.append(.menstrualCycle) }
    if viewModel.heartHealthStats != nil { pages.append(.heartHealth) }
    if viewModel.bodyWeightStats != nil { pages.append(.bodyWeight) }
    if viewModel.nutritionStats != nil { pages.append(.nutrition) }

    return pages
  }

  var totalPages: Int {
    availablePages.count
  }

  @ViewBuilder
  var currentPageView: some View {
    if currentPage < availablePages.count,
       let stats = viewModel.stats {
      switch availablePages[currentPage] {
      case .workouts:
        WorkoutsStoryPage(stats: stats)
      case .exerciseEffectiveness:
        ExerciseEffectivenessStoryPage(stats: stats)
      case .distance:
        DistanceStoryPage(stats: stats)
      case .cardioFitness:
        CardioFitnessStoryPage(stats: stats)
      case .sleep:
        if let sleepStats = viewModel.sleepStats {
          SleepStoryPage(stats: sleepStats)
        }
      case .menstrualCycle:
        if let menstrualStats = viewModel.menstrualStats {
          MenstrualCycleStoryPage(stats: menstrualStats)
        }
      case .heartHealth:
        if let heartHealthStats = viewModel.heartHealthStats {
          HeartHealthStoryPage(stats: heartHealthStats)
        }
      case .bodyWeight:
        if let bodyWeightStats = viewModel.bodyWeightStats {
          BodyWeightStoryPage(stats: bodyWeightStats)
        }
      case .nutrition:
        if let nutritionStats = viewModel.nutritionStats {
          MacroDistributionStoryPage(stats: nutritionStats)
        }
      }
    }
  }
}

// MARK: - Story Page Type

private enum StoryPageType {
  case workouts
  case exerciseEffectiveness
  case distance
  case cardioFitness
  case sleep
  case menstrualCycle
  case heartHealth
  case bodyWeight
  case nutrition
}

// MARK: - Timer Logic

private extension YearInBloomStoriesView {

  func updateProgress() {
    withAnimation(.linear(duration: tickInterval)) {
      progress += tickInterval / pageDuration
    }

    if progress >= 1.0 {
      goToNextPage()
    }
  }

  func goToNextPage() {
    withAnimation {
      if currentPage < totalPages - 1 {
        currentPage += 1
        progress = 0
      } else {
        dismiss()
      }
    }
  }

  func goToPreviousPage() {
    withAnimation {
      if progress > 0.1 {
        progress = 0
      } else if currentPage > 0 {
        currentPage -= 1
        progress = 0
      }
    }
  }
}

// MARK: - Story Progress Bar

private struct StoryProgressBar: View {
  let currentPage: Int
  let progress: CGFloat
  let totalPages: Int

  var body: some View {
    HStack(spacing: 4) {
      ForEach(0..<totalPages, id: \.self) { index in
        Capsule()
          .fill(.text.opacity(0.3))
          .overlay(alignment: .leading) {
            GeometryReader { geo in
              Capsule()
                .fill(.text)
                .frame(width: fillWidth(for: index, in: geo.size.width))
            }
          }
          .frame(height: 3)
      }
    }
  }

  func fillWidth(for index: Int, in totalWidth: CGFloat) -> CGFloat {
    if index < currentPage { return totalWidth }
    if index > currentPage { return 0 }
    return totalWidth * progress
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    YearInBloomStoriesView(year: 2024)
  }
}
