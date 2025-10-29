//
//  VoiceLoggerViewModel.swift
//  Bloom
//
//  Created by Claude on 2025-10-29.
//

import Speech
import AVFoundation
import SwiftUI
import AppUI

extension VoiceLoggerView {

  @Observable @MainActor
  final class ViewModel {
    var isRecording = false
    var transcript = ""
    var audioLevel: CGFloat = 0.0
    var saveComplete = false
    var alertDetails: AlertDetails?
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var isManualStop = false
  }
}

extension VoiceLoggerView.ViewModel {

  func requestAuthorization() async {
    await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { status in
        Task { @MainActor in
          self.authorizationStatus = status
          continuation.resume()
        }
      }
    }
  }

  func startRecording() {
    guard authorizationStatus == .authorized else {
      alertDetails = AlertDetails(
        title: "Permission Required",
        message: "Please enable Speech Recognition in Settings to use Voice Logger."
      )
      return
    }

    // Stop any existing recording
    if isRecording {
      stopRecording()
    }

    // Create and configure recognition request
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    recognitionRequest?.shouldReportPartialResults = true

    // Start recognition task
    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
      guard let self = self else { return }

      Task { @MainActor in
        // Only update transcript if not a manual stop
        if let result = result, !self.isManualStop {
          self.transcript = result.bestTranscription.formattedString
        }

        if error != nil {
          // Only show error if this wasn't a manual stop
          if !self.isManualStop {
            self.stopRecording()
            if let error = error {
              self.alertDetails = AlertDetails(
                title: "Recognition Error",
                message: error.localizedDescription
              )
            }
          }
          // Reset the flag for next recording
          self.isManualStop = false
        }
      }
    }

    // Configure audio engine
    let inputNode = audioEngine.inputNode
    let recordingFormat = inputNode.outputFormat(forBus: 0)

    // Install tap for audio level monitoring and recognition
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
      guard let self = self else { return }

      // Append buffer to recognition request
      self.recognitionRequest?.append(buffer)

      // Calculate audio level
      guard let channelData = buffer.floatChannelData?[0] else { return }
      let frames = UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength))

      let rms = sqrt(frames.map { $0 * $0 }.reduce(0, +) / Float(frames.count))
      let avgPower = 20 * log10(max(rms, 1e-10)) // Avoid log of zero
      let normalized = max(0, min(1, (avgPower + 50) / 50))

      Task { @MainActor in
        self.audioLevel = CGFloat(normalized)
      }
    }

    // Prepare and start audio engine
    audioEngine.prepare()

    do {
      try audioEngine.start()
      isRecording = true
    } catch {
      alertDetails = AlertDetails(
        title: "Recording Error",
        message: "Unable to start audio recording: \(error.localizedDescription)"
      )
    }
  }

  func stopRecording() {
    guard isRecording else { return }

    // Mark this as a manual stop
    isManualStop = true

    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionRequest = nil
    recognitionTask?.cancel()
    recognitionTask = nil
    isRecording = false
    audioLevel = 0
  }

  func toggleRecording() {
    if isRecording {
      stopRecording()
    } else {
      startRecording()
    }
  }
}
