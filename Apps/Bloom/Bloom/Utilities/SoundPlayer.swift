//
//  SoundPlayer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import UIKit
import AVFoundation

/// Sounds can be found here: https://github.com/TUNER88/iOSSystemSoundsLibrary
enum SoundPlayer {

  static func playWorkoutCountdown() {
    playSoundFile(name: "nano/WorkoutCountdown_Haptic.caf")
  }

  static func playIntervalUpcoming() {
    playSoundFile(name: "nano/IntervalUpcoming.caf")
  }

  static func playWorkoutAutodetected() {
    playSoundFile(name: "nano/WorkoutStartAutodetect.caf")
  }

  static func playHeadGestureDoubleShake() {
    playSoundFile(name: "nano/HeadGesturesDoubleShake.caf")
  }

  static func playHeadGestureDoubleNod() {
    playSoundFile(name: "nano/HeadGesturesDoubleNod.caf")
  }

  static func playLogHealthData() {
    playSoundFile(name: "nano/ReceiverConfirmation.caf")
  }

  private static func playSoundFile(name: String) {
    guard let url = URL(string: "/System/Library/Audio/UISounds/\(name)") else { return }

    var soundID: SystemSoundID = 0
    AudioServicesCreateSystemSoundID(url as CFURL, &soundID)

    guard soundID > 0 else { return }

    AudioServicesPlaySystemSound(soundID)
  }

  @MainActor
  static func playSendMessage() {
    guard UIApplication.shared.applicationState == .active else { return }

    AudioServicesPlaySystemSound(1004)
  }

  @MainActor
  static func playReceiveMessage() {
    guard UIApplication.shared.applicationState == .active else { return }

    AudioServicesPlaySystemSound(1003)
  }
}
