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

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        // Text input with dictation
        TextField("What did you eat?", text: $transcribedText, axis: .vertical)
          .lineLimit(3...6)

        Spacer(minLength: 0)

        // Action buttons
        Button("Log") {
          sendVoiceLog()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isProcessing || transcribedText.isEmpty)
      }
      .navigationTitle(meal.displayName)
      .navigationBarTitleDisplayMode(.inline)
      .padding(.bottom)
      .ignoresSafeArea(edges: .bottom)
      .animation(.default, value: transcribedText)
      .overlay {
        if isProcessing {
          ZStack {
            Color.black.opacity(0.7)
            ProgressView()
          }
          .ignoresSafeArea()
        } else if showingSuccess {
          ZStack {
            Color.black.opacity(0.7)
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 50))
              .foregroundStyle(.green)
          }
          .ignoresSafeArea()
        }
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

      guard let data = try? JSONEncoder.watch.encode(message) else {
        isProcessing = false
        return
      }

      do {
        let responseData = try await WatchChannel.shared.send(data: data)
        let response = try JSONDecoder.watch.decode(WatchVoiceFoodLogResponse.self, from: responseData)

        isProcessing = false

        if response.success {
          WKInterfaceDevice.current().play(.success)
          showingSuccess = true
          try? await Task.sleep(for: .seconds(1))
          performDismiss?()
        } else {
          WKInterfaceDevice.current().play(.failure)
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
