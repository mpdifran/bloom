//
//  CameraViewModel.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

import AVFoundation
import Combine
import SwiftUI

@MainActor
final class CameraViewModel: ObservableObject {
  let manager: CameraManager

  @Published var image: UIImage?

  let session = AVCaptureSession()

  private var subscriptions = Set<AnyCancellable>()

  init() {
    manager = CameraManager.create(with: session)
  }
}

extension CameraViewModel {
  func capturePressed() {
    Task {
      image = await manager.capture()
    }
  }
}
