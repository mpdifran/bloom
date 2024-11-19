//
//  AVFoundation+Configuration.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import AVFoundation

extension AVCaptureSession {

    func configure(_ editor: () async -> Void) async {
        beginConfiguration()
        await editor()
        commitConfiguration()
    }
}

extension AVCaptureDevice {

    func configure(_ editor: () -> Void) throws {
        try lockForConfiguration()
        editor()
        unlockForConfiguration()
    }
}
