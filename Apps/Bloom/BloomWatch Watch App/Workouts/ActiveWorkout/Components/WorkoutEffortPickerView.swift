//
//  WorkoutEffortPickerView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-11.
//

import SwiftUI
import HealthKit
import CoreHealth

struct WorkoutEffortPickerView: View {
  let workout: HKWorkout
  let onSave: (Int) -> Void

  @State private var effortValue: Double = 5
  @State private var isSaving = false
  @State private var showingSaveConfirmation = false
  @FocusState private var isFocused: Bool
  @Environment(\.dismiss) private var dismiss

  private var effortBinding: Binding<Int> {
    Binding(
      get: { Int(effortValue.rounded()) },
      set: { effortValue = Double($0) }
    )
  }

  var body: some View {
    VStack(spacing: 8) {
      Spacer(minLength: 0)

      WorkoutEffortBarView(selectedEffort: effortBinding, barHeight: 100)

      effortLabel
    }
    .focusable()
    .focused($isFocused)
    .digitalCrownRotation($effortValue, from: 1, through: 10, by: 1, sensitivity: .low)
    .sensoryFeedback(.impact(flexibility: .soft), trigger: Int(effortValue))
    .padding(.horizontal)
    .padding(.bottom)
    .navigationTitle("Effort")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button {
          Task { await save() }
        } label: {
          Image(systemName: "checkmark")
        }
        .tint(.accentColor)
        .disabled(isSaving)
      }
    }
    .frame(maxWidth: .infinity)
    .background(.black)
    .overlay {
      if isSaving {
        savingOverlay
      } else if showingSaveConfirmation {
        saveConfirmationOverlay
      }
    }
    .onAppear {
      isFocused = true
    }
  }

  private var effortLabel: some View {
    let category = WorkoutEffortCategory(effortScore: effortValue)
    return HStack(spacing: 6) {
      Text("\(Int(effortValue.rounded()))")
        .font(.caption2)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.white)
        .frame(width: 20, height: 20)
        .background(category.color, in: Circle())

      Text(category.rawValue)
        .font(.body)
        .bold()
        .fontDesign(.rounded)

      Spacer()
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - Save

private extension WorkoutEffortPickerView {

  func save() async {
    isSaving = true

    do {
      try await HealthStoreModifier.shared.logWorkoutEffort(
        effortScore: effortValue,
        for: workout
      )
      isSaving = false
      SoundPlayer.playLogHealthData()
      onSave(Int(effortValue))

      withAnimation {
        showingSaveConfirmation = true
      }

      try? await Task.sleep(for: .seconds(1))
      dismiss()
    } catch {
      isSaving = false
    }
  }
}

// MARK: - Overlays

private extension WorkoutEffortPickerView {

  var savingOverlay: some View {
    ProgressView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.ultraThinMaterial)
  }

  var saveConfirmationOverlay: some View {
    VStack {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 50))
        .foregroundStyle(.green)

      Text("Saved")
        .font(.headline)
        .bold()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.ultraThinMaterial)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      WorkoutEffortPickerView(
        workout: HKWorkout(
          activityType: .traditionalStrengthTraining,
          start: Date().addingTimeInterval(-3600),
          end: .now
        ),
        onSave: { _ in }
      )
    }
  }
}
