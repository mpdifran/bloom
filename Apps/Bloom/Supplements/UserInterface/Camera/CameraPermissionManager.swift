//
//  CameraPermissionManager.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-18.
//

import AppUI
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

  var permissionAlert: AlertDetails {
    .init(
      title: "Camera Permission Required",
      message: "Please allow camera access in Settings.",
      buttons: [
        .init(
          title: "Open Settings",
          action: { [weak self] in
            self?.openSettings()
          }
        ),
        .init(
          title: "Cancel",
          role: .cancel,
          action: {
            // Cancel
          }
        )
      ]
    )
  }

  func checkPermission() async {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      permissionState = .granted
    case .notDetermined:
      await requestPermission()
    case .denied, .restricted:
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
    permissionState = isGranted ? .granted : .denied
  }
}
