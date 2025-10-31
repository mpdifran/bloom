//
//  VoiceLoggerView.swift
//  Bloom
//
//  Created by Claude on 2025-10-29.
//

import SwiftUI
import CoreHealth
import DataContainer
import CoreNetwork
import BloomModel
import AppUI
import BloomFoundation
import SFSafeSymbols
import TelemetryDeck

struct VoiceLoggerView: View {
  let performDismiss: (() -> Void)?

  init(performDismiss: (() -> Void)? = nil) {
    self.performDismiss = performDismiss
  }

  @State private var viewModel = ViewModel()

  @FocusState private var isTextFieldFocused: Bool

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack {
        transcriptTextField

        Spacer()

        recordingButton

        Spacer()
      }
      .padding()
      .groupedBackground()
      .navigationTitle("Voice Logger")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .shelf {
        saveButton
      }
    }
    .task {
      TelemetryDeck.signal("voice_logger_opened")
      await viewModel.requestAuthorization()

      // Auto-start recording if authorized
      if viewModel.authorizationStatus == .authorized {
        viewModel.startRecording()
      } else if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted {
        TelemetryDeck.signal("voice_logger_permission_denied")
        viewModel.alertDetails = AlertDetails(
          title: "Permission Required",
          message: "Please enable Speech Recognition and Microphone access in Settings to use Voice Logger."
        )
      }
    }
    .onDisappear {
      if viewModel.isRecording {
        viewModel.stopRecording()
      }
    }
    .alert(alertDetails: $viewModel.alertDetails)
    .animation(.default, value: viewModel.audioLevel)
    .animation(.default, value: viewModel.transcript)
    .sensoryFeedback(.success, trigger: viewModel.saveComplete)
  }
}

private extension VoiceLoggerView {

  var transcriptTextField: some View {
    Group {
      if viewModel.isRecording {
        // Use Text while recording for smooth contentTransition
        Text(viewModel.transcript.isEmpty ? "Describe what you ate" : viewModel.transcript)
          .foregroundStyle(viewModel.transcript.isEmpty ? .secondary : .primary)
          .contentTransition(.numericText())
          .frame(maxWidth: .infinity, alignment: .leading)
          .onTapGesture {
            viewModel.stopRecording()
            isTextFieldFocused = true
          }
      } else {
        // Use TextField when not recording for editing
        TextField(
          "",
          text: $viewModel.transcript,
          prompt: Text("Describe what you ate"),
          axis: .vertical
        )
        .focused($isTextFieldFocused)
      }
    }
    .font(.title2)
    .fontDesign(.rounded)
    .bold()
    .multilineTextAlignment(.leading)
    .lineLimit(3...5)
    .cardContainer()
  }

  var recordingButton: some View {
    Button {
      viewModel.toggleRecording()
    } label: {
      ZStack {
        Circle()
          .fill(.background)
//          .fill(Color.orange.opacity(0.3 + (viewModel.audioLevel * 0.5)))
          .frame(width: 160, height: 160)
          .scaleEffect(1.0 + (viewModel.audioLevel * 0.5))
          .animation(.easeInOut(duration: 0.1), value: viewModel.audioLevel)

        Image(systemSymbol: viewModel.isRecording ? .microphoneFill : .microphoneSlashFill)
          .font(.system(size: 60))
          .foregroundStyle(Color.orange.opacity(0.3 + (viewModel.audioLevel * 0.5)))
      }
    }
    .buttonStyle(.plain)
    .shadow(color: .mutedOrange, radius: recordingButtonShadowRadius)
  }

  var recordingButtonShadowRadius: CGFloat {
    guard viewModel.isRecording else {
      return 0
    }

    return 30 + 30 * (viewModel.audioLevel * 0.5)
  }

  var saveButton: some View {
    AsyncButton {
      try await handleSave()
    } label: {
      Text("Save")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .disabled(viewModel.transcript.isEmpty)
  }
}

private extension VoiceLoggerView {

  func handleSave() async throws {
    guard viewModel.transcript.isNotEmpty else {
      viewModel.alertDetails = AlertDetails(
        title: "Error",
        message: "Please record something first"
      )
      return
    }

    // Stop recording if still active
    if viewModel.isRecording {
      viewModel.stopRecording()
    }

    // Generate identifier upfront
    let processingIdentifier = AIFoodProcessingIdentifier()

    do {
      // Upload to backend first
      _ = try await NetworkRequester.shared.uploadMagicScan(
        imageData: nil,
        contextText: viewModel.transcript,
        processingIdentifier: processingIdentifier
      )

      // Save locally if upload succeeded
      nutritionViewModel.logTextOnlyMagicScan(
        modelContext: modelContext,
        processingIdentifier: processingIdentifier,
        contextText: viewModel.transcript,
        date: nutritionViewModel.date,
        meal: nutritionViewModel.suggestedMeal
      )

      // Trigger feedback
      viewModel.saveComplete.toggle()
      SoundPlayer.playLogHealthData()

      TelemetryDeck.signal("voice_logger_saved", parameters: [
        "result": "success",
        "transcript_length": String(viewModel.transcript.count)
      ])

      // Dismiss to NutritionView
      performDismiss?()
      dismiss()
    } catch {
      TelemetryDeck.signal("voice_logger_saved", parameters: ["result": "failure"])
      throw error
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      VoiceLoggerView()
    }
  }
}
