//
//  CameraViewModel.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

import SwiftUI
import AVFoundation

@MainActor
final class CameraViewModel: ObservableObject {
  @ObservedObject var manager: CameraManager

  let session = AVCaptureSession()

  init() {
    manager = CameraManager.create(with: session)
  }
}
