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

  @State private var isSubTimerActive = false
  @State private var subTimerStartDate: Date? = nil
  @State private var elapsedSubTime: TimeInterval = 0
  @State private var currentSubTime: TimeInterval = 0

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
        .onChange(of: currentIndex) { oldValue, newValue in
          let exerciseSet = exerciseSets[newValue]
          withAnimation {
            scrollProxy.scrollTo(exerciseSet.id, anchor: .top)
          }

          if shouldShowSubTimer {
            resetSubTimer()

            if shouldAutoStartSubTimer {
              isSubTimerActive = true
            }
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

  var shouldShowSubTimer: Bool {
    switch exerciseSets[currentIndex].kind {
    case .rest:
      true
    case .grouped(_, let format):
      switch format {
      case .amrap, .emom, .tabata:
        true
      default:
        false
      }
    default:
      false
    }
  }

  var shouldAutoStartSubTimer: Bool {
    switch exerciseSets[currentIndex].kind {
    case .rest:
      true
    default:
      false
    }
  }

  var currentSubDuration: TimeInterval {
    let exerciseSet = exerciseSets[currentIndex]
    switch exerciseSet.kind {
    case .rest(let restTime):
      return restTime
    case .grouped:
      return exerciseSet.set.duration ?? 0
    default:
      return 0
    }
  }

  var remainingSubTime: TimeInterval {
    guard currentSubDuration > 0 else { return 0 }

    return min(currentSubDuration - currentSubTime + 1, currentSubDuration)
  }

  func resetSubTimer() {
    subTimerStartDate = Date()
    elapsedSubTime = 0
    currentSubTime = 0
    isSubTimerActive = false
  }
}

private extension WorkoutInstanceView {

  var headerView: some View {
    VStack(spacing: 20) {
      WorkoutActivityTypeTimelineView(
        activityTypes: workoutPlan.orderedSets.map(\.appleWorkoutType),
        currentIndex: currentSetIndex
      )

      timerView
        .frame(minHeight: 180)
    }
    .padding(.horizontal)
  }

  var timerView: some View {
    VStack {
      Text(timeString)
        .font(.system(size: shouldShowSubTimer ? 30 : 55))
        .foregroundStyle(.yellow)
        .contentTransition(.numericText(value: currentTime))

      if shouldShowSubTimer {
        Text(subTimeString)
          .font(.system(size: 55))
          .minimumScaleFactor(0.3)
          .lineLimit(1)
          .foregroundStyle(subTimeColor)
          .contentTransition(.numericText(value: remainingSubTime))
          .animation(.default, value: remainingSubTime)
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

      if isSubTimerActive {
        if let subTimerStartDate {
          currentSubTime = elapsedSubTime + Date().timeIntervalSince(subTimerStartDate)
        }

        if shouldShowSubTimer && remainingSubTime <= 0 {
          currentIndex += 1
        }
      }
    }
  }

  var stepsSection: some View {
    VStack(spacing: 0) {
      ForEachEnumerated(exerciseSets) { (index, exerciseSet) in
        WorkoutExerciseSetCell(
          exerciseSet: exerciseSet,
          mode: WorkoutExerciseSetCell.Mode(index: index, currentIndex: currentIndex),
          isPeeking: peekingIndex == index,
          currentSubTime: index == currentIndex ? currentSubTime : nil
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

          if shouldShowSubTimer && !isSubTimerActive {
            startTimerButton
          } else {
            nextButton
          }
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
      subTimerStartDate = Date()
      elapsedSubTime = 0
      currentSubTime = 0
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

  var startTimerButton: some View {
    AsyncButton {
      resetSubTimer()
      isSubTimerActive = true
    } label: {
      Label("Start Timer", systemSymbol: .timer)
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .tint(.blue)
  }

  var pauseButton: some View {
    AsyncButton {
      try await WorkoutController.shared.pauseWorkout()
      if let start = startDate {
        elapsedTime += Date().timeIntervalSince(start)
      }
      startDate = nil
      if let subTimerStartDate {
        elapsedSubTime += Date().timeIntervalSince(subTimerStartDate)
      }
      subTimerStartDate = nil
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
      if let subTimerStartDate {
        elapsedSubTime += Date().timeIntervalSince(subTimerStartDate)
      }
      startDate = nil
      subTimerStartDate = nil
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
      subTimerStartDate = Date()
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
      resetSubTimer()
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

  var subTimeString: String {
    let dateComponents = DateComponents(second: Int(max(remainingSubTime, 0)))
    let timeString = DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: dateComponents) ?? ""

    let exerciseSet = exerciseSets[currentIndex]

    switch exerciseSet.kind {
    case .rest:
      return "Rest \(timeString)"
    case .grouped(_, let format):
      switch format {
      case .amrap:
        return "\(timeString)"
      case .emom:
        let remainingRoundTime = Int(remainingSubTime) % 60
        let dateComponents = DateComponents(second: Int(max(remainingRoundTime, 0)))
        let roundTimeString = DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: dateComponents) ?? ""

        return "Round \(roundTimeString)"
      case .tabata:
        let cycleDuration = 30.0 // 20s work + 10s rest
        let workDuration = 20.0

        let elapsedInCycle = currentSubTime.truncatingRemainder(dividingBy: cycleDuration)
        let roundNumber = Int(currentSubTime / cycleDuration) + 1

        if elapsedInCycle < workDuration {
          let remainingTime = workDuration - elapsedInCycle
          let dateComponents = DateComponents(second: Int(max(remainingTime, 0)))
          let timeString = DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: dateComponents) ?? ""

          return "Round \(roundNumber): \(timeString)"
        } else {
          let remainingTime = cycleDuration - elapsedInCycle
          let dateComponents = DateComponents(second: Int(max(remainingTime, 0)))
          let timeString = DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: dateComponents) ?? ""

          return "Rest: \(timeString)"
        }
      default:
        return ""
      }
    default:
      return ""
    }
  }

  var subTimeColor: Color {
    switch exerciseSets[currentIndex].kind {
    case .rest:
      return .blue
    default:
      return .green
    }
  }
}

#Preview {
  PreviewEnvironment {
    WorkoutInstanceView(workoutPlan: .Preview.deadlifts)
  }
}
