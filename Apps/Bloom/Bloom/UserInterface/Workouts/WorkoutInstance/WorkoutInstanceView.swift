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
  let workoutTemplate: WorkoutTemplate

  @State private var startDate: Date? = nil
  @State private var elapsedTime: TimeInterval = 0
  @State private var currentTime: TimeInterval = 0
  @State private var status: Status = .readyToBegin

  @Namespace private var stepTransitionNamespace

  private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

  var body: some View {
    BloomScrollView {
      timerView
      stepsSection
    }
    .shelf {
      controlButtons
    }
    .animation(.easeInOut, value: status)
    .animation(.easeInOut, value: completedIndices)
    .navigationTitle(workoutTemplate.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

private extension WorkoutInstanceView {

  var headerView: some View {
    HStack(spacing: 30) {
      WorkoutTemplateIconView(
        workoutType: workoutTemplate.appleWorkoutType,
        dimension: 120
      )
    }
    .padding(.bottom, 20)
    .background(.background)
  }

  var timerView: some View {
    VStack {
      Text(timeString)
        .font(.system(size: 55))
        .fontDesign(.rounded)
        .fontWeight(.heavy)
        .monospacedDigit()
        .foregroundStyle(.green)
        .contentTransition(.numericText(value: currentTime))
        .onReceive(timer) { _ in
          guard status == .running, let startDate = startDate else { return }

          currentTime = elapsedTime + Date().timeIntervalSince(startDate)
        }
    }
    .padding(.vertical, 40)
    .horizontallyCentered()
    .cardContainer()
  }

  var equipmentSection: some View {
    VStack {
      SectionTitleView("Equipment")
        .padding(.horizontal)

      Text(equipmentDescription)
        .horizontalAlignment(.leading)
        .cardContainer()
    }
  }

  var appleWorkoutSection: some View {
    VStack {
      LabeledContent("Workout Type") {
        Text(workoutTemplate.appleWorkoutType.name)
          .multilineTextAlignment(.trailing)
      }
      .frame(height: 50)
    }
    .horizontallyCentered()
    .cardContainer()
  }

  var stepsSection: some View {
    VStack {
      ZStack {
        ForEach(completedIndices, id: \.self) { index in
          let position = completedIndices.firstIndex(of: index)!
          let distance = min(completedIndices.count - position, 2)

          WorkoutStepCell(
            step: steps[index],
            state: .complete,
            currentTime: steps[index].duration
          )
          .matchedGeometryEffect(id: steps[index].id, in: stepTransitionNamespace)
          .scaleEffect(max(0.5, 1 - CGFloat(distance) * 0.05))
          .offset(x: 0, y: -(CGFloat(distance) * 20))
        }

        if let currentIndex = steps.indices.firstIndex(where: { state(for: $0) == .current }) {
          WorkoutStepCell(
            step: steps[currentIndex],
            state: .current,
            currentTime: currentTime(for: currentIndex)
          )
          .matchedGeometryEffect(id: steps[currentIndex].id, in: stepTransitionNamespace)
        }
      }
      .padding(.top, CGFloat(min(completedIndices.count, 2) * 20))

      ForEachEnumerated(steps) { index, step in
        if state(for: index) == .upcoming {
          WorkoutStepCell(
            step: step,
            state: state(for: index),
            currentTime: currentTime(for: index)
          )
          .matchedGeometryEffect(id: steps[index].id, in: stepTransitionNamespace, properties: .frame, isSource: true)
        }
      }
    }
    .padding(.top)
  }
}

private extension WorkoutInstanceView {

  var steps: [WorkoutStep] {
    workoutTemplate.steps ?? []
  }

  var completedIndices: [Int] {
    steps.indices.filter { state(for: $0) == .complete }
  }
}

private extension WorkoutInstanceView {

  @ViewBuilder
  var controlButtons: some View {
    switch status {
    case .readyToBegin:
      AsyncButton {
        try await WorkoutController.shared.startWorkout(type: workoutTemplate.appleWorkoutType)
        startDate = Date()
        elapsedTime = 0
        currentTime = 0
        status = .running
      } label: {
        Label("Start Workout", systemSymbol: SFSymbol(rawValue: workoutTemplate.appleWorkoutType.systemImage))
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .tint(.green)
    case .running:
      HStack {
        AsyncButton {
          try await WorkoutController.shared.pauseWorkout()
          if let start = startDate {
            elapsedTime += Date().timeIntervalSince(start)
          }
          startDate = nil
          status = .paused
        } label: {
          Label("Pause", systemSymbol: .pauseFill)
            .horizontallyCentered()
        }
        .tint(.yellow)

        AsyncButton {
          try await WorkoutController.shared.endWorkout()
          if let start = startDate {
            elapsedTime += Date().timeIntervalSince(start)
          }
          startDate = nil
          status = .ended
        } label: {
          Label("End", systemSymbol: .stopFill)
            .horizontallyCentered()
        }
        .tint(.red)
      }
      .buttonStyle(.primary)
    case .paused:
      HStack(spacing: 16) {
        AsyncButton {
          try await WorkoutController.shared.resumeWorkout()
          startDate = Date()
          status = .running
        } label: {
          Label("Resume", systemSymbol: .playFill)
            .horizontallyCentered()
        }
        .tint(.green)

        AsyncButton {
          try await WorkoutController.shared.endWorkout()
          startDate = nil
          status = .ended
        } label: {
          Label("End", systemSymbol: .stopFill)
            .horizontallyCentered()
        }
        .tint(.red)
      }
      .buttonStyle(.primary)
    case .ended:
      AsyncButton {
        try await WorkoutController.shared.startWorkout(type: workoutTemplate.appleWorkoutType)
        startDate = Date()
        elapsedTime = 0
        currentTime = 0
        status = .running
      } label: {
        Label("Restart Workout", systemSymbol: .arrowCounterclockwise)
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .tint(.green)
    }
  }
}

private extension WorkoutInstanceView {

  func state(for stepIndex: Int) -> WorkoutStepCell.State {
    guard let steps = workoutTemplate.steps else { return .upcoming }
    guard status != .readyToBegin else { return .upcoming }

    let start = steps.prefix(stepIndex).reduce(0) { $0 + $1.duration }
    let end = start + steps[stepIndex].duration
    if currentTime >= end {
      return .complete
    } else if currentTime >= start {
      return .current
    } else {
      return .upcoming
    }
  }

  func currentTime(for index: Int) -> TimeInterval {
    guard let steps = workoutTemplate.steps else { return 0 }

    let elapsedBefore = steps.prefix(index).reduce(0) { $0 + $1.duration }
    let timeInStep = currentTime - elapsedBefore

    return min(max(timeInStep, 0), steps[index].duration)
  }

  var equipmentDescription: String {
    let names = workoutTemplate.equipment.map({ $0.name })
    return ListFormatter.localizedString(byJoining: names)
  }

  var timeString: String {
    let totalMilliseconds = Int(currentTime * 1000)
    let minutes = totalMilliseconds / 60000
    let seconds = (totalMilliseconds % 60000) / 1000
    let milliseconds = (totalMilliseconds % 1000) / 100
    return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      WorkoutInstanceView(workoutTemplate: .Preview.deadlifts)
    }
  }
}
