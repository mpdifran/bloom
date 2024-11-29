//
//  CameraPermissionManager.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-18.
//

import AVFoundation
import SwiftUI

// MARK: - CameraPermissionManager

@MainActor
final class CameraPermissionManager: ObservableObject {
  static let shared = CameraPermissionManager()

  enum State {
    case pending
    case granted
    case denied
  }

  @Published var permissionState: State = .pending
  @Published var shouldShowAlert: Bool = false

  func checkPermission() async {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      permissionState = .granted
    case .notDetermined:
      await requestPermission()
    case .denied, .restricted:
      shouldShowAlert = true
      permissionState = .denied
    @unknown default:
      permissionState = .denied
    }
  }

  func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }
}

// MARK: Private Methods

private extension CameraPermissionManager {
  func requestPermission() async {
    let isGranted = await AVCaptureDevice.requestAccess(for: .video)
    if isGranted {
      permissionState = .granted
    } else {
      shouldShowAlert = true
      permissionState = .denied
    }
  }
}
