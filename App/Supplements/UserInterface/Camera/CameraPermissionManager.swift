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

  @Published var isPermissionGranted: Bool = false
  @Published var shouldShowAlert: Bool = false

  func checkPermission() async {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      isPermissionGranted = true
    case .notDetermined:
      await requestPermission()
    case .denied, .restricted:
      shouldShowAlert = true
      isPermissionGranted = false
    @unknown default:
      isPermissionGranted = false
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
    isPermissionGranted = await AVCaptureDevice.requestAccess(for: .video)
    if !isPermissionGranted {
      shouldShowAlert = true
    }
  }
}
