//
//  LogBowelMovementView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import SwiftUI
import BloomFoundation
import CoreHealth
import TelemetryDeck
import SFSafeSymbols

private extension CGFloat {
  static let cellWidth: CGFloat = 60
  static let cellHeight: CGFloat = 60
}

struct LogBowelMovementView: View {
  let performDismiss: (() -> Void)?

  @State private var selectedStoolType: Int = 0
  @State private var selectedDuration: Int = 1
  @State private var isSaving = false
  @State private var showingSaveConfirmation = false
  @FocusState private var isFocused: Bool

  private let pendingManager = PendingBowelMovementManager.shared

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        stoolTypePicker
        durationPicker
        saveButton
      }
      .padding()
    }
    .navigationTitle("Bowel Movement")
    .overlay {
      if isSaving {
        savingOverlay
      } else if showingSaveConfirmation {
        saveConfirmationOverlay
      }
    }
  }
}

// MARK: - Stool Type Picker

private extension LogBowelMovementView {

  var stoolTypePicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Type")
        .font(.caption)
        .foregroundStyle(.secondary)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          unknownTypeCell

          ForEach(1...7, id: \.self) { type in
            stoolTypeCell(type: type)
          }
        }
        .padding(2)
      }
    }
  }

  var unknownTypeCell: some View {
    VStack(spacing: 4) {
      Image(systemSymbol: .questionmarkCircleFill)
        .font(.title2)


      Text("?")
        .font(.caption2)
        .bold()
    }
    .foregroundStyle(.black)
    .frame(width: .cellWidth, height: .cellHeight)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(.white)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(selectedStoolType == 0 ? Color.brown : Color.clear, lineWidth: 2)
    )
    .onTapGesture {
      selectedStoolType = 0
    }
  }

  func stoolTypeCell(type: Int) -> some View {
    VStack(spacing: 4) {
      Image(bristolStoolTypeImage(for: type))
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 4))

      Text("\(type)")
        .font(.caption2)
        .foregroundStyle(.black)
        .bold()
    }
    .frame(width: .cellWidth, height: .cellHeight)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(.white)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(selectedStoolType == type ? Color.brown : Color.clear, lineWidth: 2)
    )
    .onTapGesture {
      selectedStoolType = type
    }
  }

  func bristolStoolTypeImage(for type: Int) -> ImageResource {
    switch type {
    case 1: .bristolStoolType1
    case 2: .bristolStoolType2
    case 3: .bristolStoolType3
    case 4: .bristolStoolType4
    case 5: .bristolStoolType5
    case 6: .bristolStoolType6
    case 7: .bristolStoolType7
    default: .bristolStoolType1
    }
  }
}

// MARK: - Duration Picker

private extension LogBowelMovementView {

  var durationPicker: some View {
    Picker("Duration", selection: $selectedDuration) {
      Text("< 5 min").tag(0)
      Text("5-10 min").tag(1)
      Text("> 10 min").tag(2)
    }
    .pickerStyle(.navigationLink)
  }
}

// MARK: - Save Button

private extension LogBowelMovementView {

  var saveButton: some View {
    Button {
      Task { await save() }
    } label: {
      Text("Save")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(.brown)
    .disabled(isSaving)
  }

  func save() async {
    isSaving = true
    defer { isSaving = false }

    let entry = WatchBowelMovementEntry(
      date: .now,
      bristolStoolType: selectedStoolType,
      rawDuration: selectedDuration
    )

    let success = await pendingManager.add(entry)

    TelemetryDeck.signal("Watch Log Bowel Movement", parameters: [
      "synced": success ? "true" : "false"
    ])

    // Show confirmation regardless of sync status - data is cached
    SoundPlayer.playLogHealthData()
    withAnimation {
      showingSaveConfirmation = true
    }

    try? await Task.sleep(for: .seconds(1))

    performDismiss?()
  }
}

// MARK: - Overlays

private extension LogBowelMovementView {

  var savingOverlay: some View {
    ProgressView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.ultraThinMaterial)
  }

  var saveConfirmationOverlay: some View {
    VStack {
      Image(systemSymbol: .checkmarkCircleFill)
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
      LogBowelMovementView(performDismiss: nil)
    }
  }
}
