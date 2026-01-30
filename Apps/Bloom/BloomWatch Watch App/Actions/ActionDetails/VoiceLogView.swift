//
//  VoiceLogView.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import BloomFoundation
import WatchKit

struct VoiceLogView: View {
  let meal: WatchMeal
  let performDismiss: (() -> Void)?

  @State private var transcribedText = ""
  @State private var isProcessing = false
  @State private var showingSuccess = false
  @State private var showingDictation = true

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        if !transcribedText.isEmpty {
          // Show transcribed text
          ScrollView {
            Text(transcribedText)
              .font(.body)
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, alignment: .leading)
              .contentTransition(.numericText())
          }
          .frame(maxHeight: 80)

          // Action buttons
          HStack(spacing: 12) {
            Button("Retry") {
              transcribedText = ""
              showingDictation = true
            }
            .buttonStyle(.bordered)

            Button("Log") {
              sendVoiceLog()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)
          }
        } else {
          // Prompt to speak
          VStack(spacing: 12) {
            Image(systemName: "mic.circle.fill")
              .font(.system(size: 50))
              .foregroundStyle(.accent)

            Text("What did you eat?")
              .font(.headline)
              .fontDesign(.rounded)

            Text("Say something like:\n\"chicken breast with rice and broccoli\"")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
      .padding()
      .navigationTitle(meal.displayName)
      .navigationBarTitleDisplayMode(.inline)
      .animation(.default, value: transcribedText)
      .overlay {
        if isProcessing {
          ProgressView()
        } else if showingSuccess {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 50))
            .foregroundStyle(.green)
        }
      }
      .onAppear {
        if showingDictation {
          presentDictation()
        }
      }
    }
  }

  private func presentDictation() {
    showingDictation = false

    WKExtension.shared().visibleInterfaceController?.presentTextInputController(
      withSuggestions: nil,
      allowedInputMode: .plain
    ) { results in
      if let text = results?.first as? String, !text.isEmpty {
        transcribedText = text
      }
    }
  }

  private func sendVoiceLog() {
    guard !transcribedText.isEmpty, !isProcessing else { return }

    isProcessing = true

    Task {
      let message = WatchVoiceFoodLogMessage(
        transcribedText: transcribedText,
        meal: meal.rawValue
      )

      guard let data = try? JSONEncoder().encode(message) else {
        isProcessing = false
        return
      }

      do {
        let responseData = try await WatchChannel.shared.send(data: data)
        let response = try JSONDecoder().decode(WatchVoiceFoodLogResponse.self, from: responseData)

        isProcessing = false

        if response.success {
          WKInterfaceDevice.current().play(.success)
          showingSuccess = true
          try? await Task.sleep(for: .seconds(1))
          performDismiss?()
        }
      } catch {
        isProcessing = false
        WKInterfaceDevice.current().play(.failure)
      }
    }
  }
}

#Preview {
  VoiceLogView(meal: .lunch, performDismiss: nil)
}
