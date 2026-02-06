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
  static let cellCornerRadius: CGFloat = 16
  static let selectedBorderWidth: CGFloat = 4
}

struct LogBowelMovementView: View {
  let performDismiss: (() -> Void)?

  @State private var selectedStoolType: Int = 0
  @State private var selectedDuration: Int = 1
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
    }
    .navigationTitle("Bowel Movement")
    .frame(maxWidth: .infinity)
    .background(.black)
    .overlay {
      if showingSaveConfirmation {
        saveConfirmationOverlay
      }
    }
  }
}

// MARK: - Stool Type Picker

private extension LogBowelMovementView {

  var stoolTypePicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          unknownTypeCell

          ForEach(1...7, id: \.self) { type in
            stoolTypeCell(type: type)
          }
        }
        .padding(.horizontal)
        .padding(.vertical, .selectedBorderWidth / 2)
      }
    }
    .ignoresSafeArea(edges: .horizontal)
    .sensoryFeedback(.selection, trigger: selectedStoolType)
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
      RoundedRectangle(cornerRadius: .cellCornerRadius)
        .fill(.white)
    )
    .overlay(
      RoundedRectangle(cornerRadius: .cellCornerRadius)
        .stroke(.brown, lineWidth: selectedStoolType == 0 ? .selectedBorderWidth : 0)
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
        .padding(.horizontal, .selectedBorderWidth / 2)

      Text("\(type)")
        .font(.caption2)
        .foregroundStyle(.black)
        .bold()
    }
    .frame(width: .cellWidth, height: .cellHeight)
    .background(
      RoundedRectangle(cornerRadius: .cellCornerRadius)
        .fill(.white)
    )
    .overlay(
      RoundedRectangle(cornerRadius: .cellCornerRadius)
        .stroke(.brown, lineWidth: selectedStoolType == type ? .selectedBorderWidth : 0)
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
      save()
    } label: {
      Text("Save")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(.brown)
    .disabled(showingSaveConfirmation)
  }

  func save() {
    guard !showingSaveConfirmation else { return }

    let entry = WatchBowelMovementEntry(
      date: .now,
      bristolStoolType: selectedStoolType,
      rawDuration: selectedDuration
    )

    // Queue locally and sync in background - returns immediately
    pendingManager.add(entry)

    TelemetryDeck.signal("Watch Log Bowel Movement")

    // Show confirmation immediately - data is safely queued
    SoundPlayer.playLogHealthData()
    withAnimation {
      showingSaveConfirmation = true
    }

    // Dismiss after brief confirmation
    Task {
      try? await Task.sleep(for: .seconds(1))
      performDismiss?()
    }
  }
}

// MARK: - Overlays

private extension LogBowelMovementView {

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
