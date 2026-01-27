//
//  SoundPlayer.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import WatchKit

enum SoundPlayer {

  static func playLogHealthData() {
    WKInterfaceDevice.current().play(.success)
  }
}
