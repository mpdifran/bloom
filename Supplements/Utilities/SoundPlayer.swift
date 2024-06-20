//
//  SoundPlayer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import UIKit
import AVFoundation

/// Sounds can be found here: https://github.com/TUNER88/iOSSystemSoundsLibrary
struct SoundPlayer {

    static func playSendMessage() {
        guard UIApplication.shared.applicationState == .active else { return }

        AudioServicesPlaySystemSound(1004)
    }

    static func playReceiveMessage() {
        guard UIApplication.shared.applicationState == .active else { return }

        AudioServicesPlaySystemSound(1003)
    }
}
