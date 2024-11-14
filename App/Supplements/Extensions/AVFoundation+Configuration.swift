//
//  AVFoundation+Configuration.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import AVFoundation

extension AVCaptureSession {

    func configure(_ editor: () -> Void) {
        beginConfiguration()
        editor()
        commitConfiguration()
    }
}
