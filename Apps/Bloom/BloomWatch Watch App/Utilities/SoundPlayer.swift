//
//  SoundPlayer.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import WatchKit
import AudioToolbox

enum SoundPlayer {

  static func playLogHealthData() {
    WKInterfaceDevice.current().play(.success)
  }
  
  /// Plays the Apple Watch workout countdown beep (for 3, 2, 1)
  /// This matches the native Apple Workout app countdown beeps
  static func playWorkoutCountdownBeep() {
    // System sound for workout countdown beeps
    // Based on iOS system sounds research, 1253-1255 are workout-related
    AudioServicesPlaySystemSound(1254)
  }
  
  /// Plays the Apple Watch workout start sound (for GO!)
  /// Higher pitched sound to indicate workout has begun
  static func playWorkoutStart() {
    // Use a different system sound for the "GO!" moment
    // System sound 1255 is often the workout start sound
    AudioServicesPlaySystemSound(1255)
    // Also provide haptic feedback for the start
    WKInterfaceDevice.current().play(.start)
  }
}
