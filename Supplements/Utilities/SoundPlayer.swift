//
//  SoundPlayer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import AVFoundation

/// Sounds can be found here: https://github.com/TUNER88/iOSSystemSoundsLibrary
struct SoundPlayer {

    static func playSendMessage() {
        AudioServicesPlaySystemSound(1004)
    }

    static func playReceiveMessage() {
        AudioServicesPlaySystemSound(1003)
    }
}
