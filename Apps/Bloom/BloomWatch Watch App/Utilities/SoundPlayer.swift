//
//  SoundPlayer.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import WatchKit
import AVFoundation

enum SoundPlayer {

  private static var audioPlayer: AVAudioPlayer?

  static func playLogHealthData() {
    WKInterfaceDevice.current().play(.success)
  }

  /// Plays the Apple Watch workout countdown sound (3, 2, 1, GO!)
  /// This matches the native Apple Workout app countdown sound
  static func playWorkoutCountdown(delay: TimeInterval = 0.3) {
    guard let url = Bundle.main.url(forResource: "WorkoutCountdown_Haptic", withExtension: "caf") else { return }
    guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
    audioPlayer = player
    player.play(atTime: player.deviceCurrentTime + delay)
  }
}
