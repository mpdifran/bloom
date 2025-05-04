//
//  WorkoutInstanceView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import AppUI
import DataContainer
import SFSafeSymbols

extension WorkoutInstanceView {
  enum Status {
    case readyToBegin
    case running
    case paused
    case ended
  }
}

struct WorkoutInstanceView: View {
  private let workoutPlan: WorkoutPlan
  private let exerciseSets: [WorkoutExerciseSet]

  init(workoutPlan: WorkoutPlan) {
    self.workoutPlan = workoutPlan
    self.exerciseSets = workoutPlan.expandedExerciseSets()
  }

  @State private var startDate: Date? = nil
  @State private var elapsedTime: TimeInterval = 0
  @State private var currentTime: TimeInterval = 0

  @State private var restStartDate: Date? = nil
  @State private var elapsedRestTime: TimeInterval = 0
  @State private var currentRestTime: TimeInterval = 0

  @State private var status: Status = .readyToBegin

  @State private var currentIndex = 0
  @State private var peekingIndex: Int?

  @Environment(\.dismiss) private var dismiss

  @Namespace private var setTransitionNamespace

  private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

  var body: some View {
    VStack(spacing: 0) {
      headerView
        .background {
          Rectangle()
            .fill(.background)
            .ignoresSafeArea()
        }

      ScrollViewReader { scrollProxy in
        ScrollView {
          VStack {
            stepsSection
          }
          .padding()
        }
        .background {
          Rectangle()
            .fill(.background.secondary)
            .ignoresSafeArea()
        }
        .onChange(of: currentIndex ?? -1) { oldValue, newValue in
          let exerciseSet = exerciseSets[newValue]
          withAnimation {
            scrollProxy.scrollTo(exerciseSet.id, anchor: .top)
          }

          if isRestTime {
            resetRestTimer()
          }
        }
      }
    }
    .shelf {
      controlButtons
    }
    .animation(.easeInOut, value: status)
    .animation(.easeInOut, value: currentIndex)
    .sensoryFeedback(.selection, trigger: status)
    .sensoryFeedback(.impact, trigger: currentIndex)
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

private extension WorkoutInstanceView {

  var isRestTime: Bool {
    switch exerciseSets[currentIndex].kind {
    case .rest:
      return true
    default:
      return false
    }
  }

  var currentRestDuration: TimeInterval {
    switch exerciseSets[currentIndex].kind {
    case .rest(let rest):
      return rest
    default:
      return 0
    }
  }

  var remainingRestTime: TimeInterval {
    currentRestDuration - currentRestTime + 1
  }

  func resetRestTimer() {
    restStartDate = Date()
    elapsedRestTime = 0
    currentRestTime = 0
  }
}

private extension WorkoutInstanceView {

  var headerView: some View {
    VStack(spacing: 20) {
      WorkoutActivityTypeTimelineView(
        activityTypes: workoutPlan.sets?.map(\.appleWorkoutType) ?? [],
        currentIndex: currentSetIndex
      )
      .padding(.horizontal)

      timerView
        .frame(minHeight: 180)
    }
  }

  var timerView: some View {
    VStack {
      Text(timeString)
        .font(.system(size: isRestTime ? 30 : 55))
        .foregroundStyle(.yellow)
        .contentTransition(.numericText(value: currentTime))

      if isRestTime {
        Text(restTimeString)
          .font(.system(size: 55))
          .foregroundStyle(.blue)
          .contentTransition(.numericText(value: remainingRestTime))
          .animation(.default, value: remainingRestTime)
          .transition(.scale)
      }
    }
    .fontDesign(.rounded)
    .fontWeight(.heavy)
    .monospacedDigit()
    .horizontallyCentered()
    .onReceive(timer) { _ in
      guard status == .running else { return }

      if let startDate {
        currentTime = elapsedTime + Date().timeIntervalSince(startDate)
      }

      if let restStartDate {
        currentRestTime = elapsedRestTime + Date().timeIntervalSince(restStartDate)
      }

      if isRestTime && remainingRestTime <= 0 {
        currentIndex += 1
      }
    }
  }

  var stepsSection: some View {
    VStack(spacing: 0) {
      ForEachEnumerated(exerciseSets) { (index, exerciseSet) in
        WorkoutExerciseSetCell(
          exerciseSet: exerciseSet,
          mode: WorkoutExerciseSetCell.Mode(index: index, currentIndex: currentIndex),
          isPeeking: peekingIndex == index
        )
        .padding(.top, 8)
        .onTapGesture {
          let mode = WorkoutExerciseSetCell.Mode(index: index, currentIndex: currentIndex)

          if mode != .current {
            if peekingIndex == index {
              peekingIndex = nil
            } else {
              peekingIndex = index
            }
          }
        }
        .contextMenu {
          if status == .running {
            Button("Jump to Here", systemSymbol: .arrowTurnRightDown) {
              currentIndex = index
            }
          }
        }
      }
    }
  }
}

private extension WorkoutInstanceView {

  var sets: [WorkoutSet] {
    workoutPlan.orderedSets
  }

  var currentSetIndex: Int {
    let currentExerciseSet = exerciseSets[currentIndex]

    return sets.firstIndex(where: { $0.id == currentExerciseSet.set.id }) ?? 0
  }
}

private extension WorkoutInstanceView {

  @ViewBuilder
  var controlButtons: some View {
    switch status {
    case .readyToBegin:
      startWorkoutButton
    case .running:
      VStack {
        HStack {
          previousButton
          nextButton
        }
        HStack {
          pauseButton
          endButton
        }
      }
    case .paused:
      HStack {
        resumeButton
        endButton
      }
    case .ended:
      restartButton
    }
  }

  var startWorkoutButton: some View {
    AsyncButton {
      try await WorkoutController.shared.startWorkout(type: workoutPlan.representativeAppleWorkoutType)
      startDate = Date()
      elapsedTime = 0
      currentTime = 0
      restStartDate = Date()
      elapsedRestTime = 0
      currentRestTime = 0
      status = .running
    } label: {
      Label("Start Workout", systemSymbol: SFSymbol(rawValue: workoutPlan.representativeAppleWorkoutType.systemImage))
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .tint(.green)
  }

  var previousButton: some View {
    AsyncButton {
      currentIndex -= 1
    } label: {
      Label("Previous", systemSymbol: .backwardFill)
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .tint(.green)
    .disabled(currentIndex == 0)
  }

  var nextButton: some View {
    AsyncButton {
      currentIndex += 1
    } label: {
      Label("Next", systemSymbol: .forwardFill)
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .tint(.green)
    .disabled(currentIndex + 1 == exerciseSets.count)
  }

  var pauseButton: some View {
    AsyncButton {
      try await WorkoutController.shared.pauseWorkout()
      if let start = startDate {
        elapsedTime += Date().timeIntervalSince(start)
      }
      startDate = nil
      if let restStartDate {
        elapsedRestTime += Date().timeIntervalSince(restStartDate)
      }
      restStartDate = nil
      status = .paused
    } label: {
      Label("Pause", systemSymbol: .pauseFill)
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .tint(.yellow)
  }

  var endButton: some View {
    AsyncButton {
      try await WorkoutController.shared.endWorkout()
      if let startDate {
        elapsedTime += Date().timeIntervalSince(startDate)
      }
      if let restStartDate {
        elapsedRestTime += Date().timeIntervalSince(restStartDate)
      }
      startDate = nil
      restStartDate = nil
      status = .ended
      dismiss()
    } label: {
      Label("End", systemSymbol: .stopFill)
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .tint(.red)
  }

  var resumeButton: some View {
    AsyncButton {
      try await WorkoutController.shared.resumeWorkout()
      startDate = Date()
      restStartDate = Date()
      status = .running
    } label: {
      Label("Resume", systemSymbol: .playFill)
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .tint(.green)
  }

  var restartButton: some View {
    AsyncButton {
      try await WorkoutController.shared.startWorkout(type: workoutPlan.representativeAppleWorkoutType)
      currentIndex = 0
      startDate = Date()
      elapsedTime = 0
      currentTime = 0
      restStartDate = Date()
      elapsedRestTime = 0
      currentRestTime = 0
      status = .running
    } label: {
      Label("Restart Workout", systemSymbol: .arrowCounterclockwise)
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .tint(.green)
  }
}

private extension WorkoutInstanceView {

  var timeString: String {
    let totalMilliseconds = Int(currentTime * 1000)
    let minutes = totalMilliseconds / 60000
    let seconds = (totalMilliseconds % 60000) / 1000
    let milliseconds = (totalMilliseconds % 1000) / 100
    return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
  }

  var restTimeString: String {
    let dateComponents = DateComponents(second: Int(max(remainingRestTime, 0)))
    let timeString = DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: dateComponents) ?? ""

    return "Rest \(timeString)"
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutInstanceView(workoutPlan: .Preview.deadlifts)
  }
}
