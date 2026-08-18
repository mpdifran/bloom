//
//  CameraManager.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

@preconcurrency import AVFoundation
import CoreImage
import UIKit
import BloomFoundation
import TelemetryDeck

// MARK: - CameraManager

@MainActor
final class CameraManager: NSObject {

  var onNewBarcode: ((String) -> Void)?

  /// Photo size to ask for, when the active format supports it. Capped rather than maximal: a
  /// magic scan is uploaded over cellular, so more pixels cost the user time for no gain.
  private static let preferredPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)

  private var isInitialized = false
  private var capturedImageContinuation: CheckedContinuation<UIImage?, Never>?
  private var deviceInput: AVCaptureDeviceInput?

  /// Largest size the active format supports that isn't bigger than `preferredPhotoDimensions`.
  ///
  /// Never hardcode this: a device whose active format doesn't list the size we ask for fails the
  /// capture outright, which surfaces as a photo that silently never arrives.
  private var supportedPhotoDimensions: CMVideoDimensions? {
    guard let supported = deviceInput?.device.activeFormat.supportedMaxPhotoDimensions,
          !supported.isEmpty else {
      return nil
    }

    let preferred = Self.preferredPhotoDimensions
    let withinPreferred = supported.filter {
      $0.width <= preferred.width && $0.height <= preferred.height
    }

    // Fall back to the format's smallest if everything it offers is larger than we asked for.
    return (withinPreferred.isEmpty ? supported : withinPreferred)
      .max { ($0.width, $0.height) < ($1.width, $1.height) }
  }

  let captureSession = AVCaptureSession()
  private let photoOutput = AVCapturePhotoOutput()
  private let metadataOutput = AVCaptureMetadataOutput()
}

// MARK: Public Methods

extension CameraManager {

  nonisolated func start() {
    Task.detached { [weak self] in
      guard let self = self else { return }

      await MainActor.run {
        self.configureCaptureSession()
      }

      let session = await self.captureSession
      session.startRunning()
    }
  }

  func stop() {
    guard captureSession.isRunning else { return }

    captureSession.stopRunning()
  }

  func capture() async -> UIImage? {
    return await withCheckedContinuation { continuation in
      var photoSettings = AVCapturePhotoSettings()

      capturedImageContinuation?.resume(returning: nil)
      capturedImageContinuation = continuation

      if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
        photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
      }

      // Must match what the output was configured with, and the output only accepts sizes the
      // active format lists. Asking for anything else fails the capture - including asking for
      // 0x0, which is what the output still reads as before setPhotoOutputProperties() has run.
      let outputDimensions = photoOutput.maxPhotoDimensions
      if outputDimensions.width > 0 && outputDimensions.height > 0 {
        photoSettings.maxPhotoDimensions = outputDimensions
      }
      photoSettings.photoQualityPrioritization = .balanced

      photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
  }

  func setFocus(for point: CGPoint) async {
    guard let camera = deviceInput?.device else { return }

    do {
      try camera.configure {
        if camera.isFocusPointOfInterestSupported {
          camera.focusPointOfInterest = point
        }
        if camera.isFocusModeSupported(.autoFocus) {
          camera.focusMode = .autoFocus
        }
        if camera.isExposurePointOfInterestSupported {
          camera.exposurePointOfInterest = point
        }
        if camera.isExposureModeSupported(.autoExpose) {
          camera.exposureMode = .autoExpose
        }
      }
    } catch {
      print("Error setting camera focus: \(error.localizedDescription)")
    }
  }
}

// MARK: Private Methods

private extension CameraManager {
  func configureCaptureSession() {
    guard !isInitialized else { return }

    captureSession.configure {
      captureSession.sessionPreset = .photo

      setupVideoInput()
      setupPhotoOutput()

      isInitialized = true

      // After the camera is initialized, we need to reset the zoom scale for 1x camera (0.5x is default).
      // We cannot set the zoom factor when setting up the video input initially, it must be done after.
      resetZoomScale()
    }
  }

  func setupVideoInput() {
    do {
      // Choose the best available camera for close up focus (wider the better).
      let discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [
//          .builtInUltraWideCamera,
//          .builtInTelephotoCamera,
          .builtInTripleCamera,
          .builtInDualCamera,
        ],
        mediaType: .video,
        position: .back
      )

      guard let camera = discoverySession.devices.first ?? AVCaptureDevice.default(for: .video) else {
        return
      }

      do {
        try camera.configure {
          if camera.isFocusPointOfInterestSupported {
            camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
          }

          if camera.isFocusModeSupported(.continuousAutoFocus) {
            camera.focusMode = .continuousAutoFocus
          } else if camera.isFocusModeSupported(.autoFocus) {
            camera.focusMode = .autoFocus
          }

          if camera.isExposureModeSupported(.continuousAutoExposure) {
            camera.exposureMode = .continuousAutoExposure
          }

          if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            camera.whiteBalanceMode = .continuousAutoWhiteBalance
          }
        }
      } catch {
        print("Error configuring camera: \(error.localizedDescription)")
      }

      let videoInput = try AVCaptureDeviceInput(device: camera)

      guard captureSession.canAddInput(videoInput) else {
        print("CameraManager: Could not add video input to session")
        return
      }

      captureSession.addInput(videoInput)
      deviceInput = videoInput
    } catch {
      print("CameraManager: Could not create video input: \(error)")
    }
  }

  func setupPhotoOutput() {
    if captureSession.canAddOutput(photoOutput) {
      captureSession.addOutput(photoOutput)
    } else {
      print("CameraManager: Could not add photo output to session")
    }

    if captureSession.canAddOutput(metadataOutput) {
      captureSession.addOutput(metadataOutput)
    } else {
      print("CameraManager: Could not add metadata output to session")
    }

    Task {
      await setPhotoOutputProperties()
    }
  }

  /// Recursively call this function until the capture session is running.
  func setPhotoOutputProperties() async {
    guard
      captureSession.isRunning,
      deviceInput?.device.activeFormat != nil
    else {
      await Delay(100)
      await setPhotoOutputProperties()
      return
    }

    if let supportedPhotoDimensions {
      photoOutput.maxPhotoDimensions = supportedPhotoDimensions
    }
    photoOutput.maxPhotoQualityPrioritization = .quality

    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "com.lotus-labs.camera-manager.metadata-objects"))
    metadataOutput.metadataObjectTypes = [.ean13, .ean8]
  }

  func resetZoomScale() {
    guard let camera = deviceInput?.device else { return }

    do {
      try camera.configure {
        // Find the zoomFactor to switch over to the next lens.
        guard let zoomFactor = camera.virtualDeviceSwitchOverVideoZoomFactors.first as? CGFloat else { return }
        camera.videoZoomFactor = zoomFactor
      }
    } catch {
      print("Error setting camera zoom: \(error.localizedDescription)")
    }
  }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {

  nonisolated func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    let sendableImage = SendableImage(data: photo.fileDataRepresentation(), error: error)
    Task {
      await handlePhotoOutput(sendableImage: sendableImage)
    }
  }

  private func handlePhotoOutput(sendableImage: SendableImage) {
    defer { capturedImageContinuation = nil }

    if let error = sendableImage.error {
      report(failure: error.localizedDescription)
      capturedImageContinuation?.resume(returning: nil)
      capturedImageContinuation = nil
      return
    }

    if let imageData = sendableImage.data,
       let image = UIImage(data: imageData)
    {
      capturedImageContinuation?.resume(returning: image)
    } else {
      report(failure: sendableImage.data == nil ? "No photo data" : "Photo data was not an image")
      capturedImageContinuation?.resume(returning: nil)
    }
    capturedImageContinuation = nil
  }

  /// A capture that yields no image used to fail silently, which is how magic scan could break for
  /// ten days without leaving a single trace in telemetry or on the server.
  private func report(failure: String) {
    let dimensions = photoOutput.maxPhotoDimensions
    let message = "\(failure) [requested: \(dimensions.width)x\(dimensions.height)]"

    print("CameraManager: Error capturing photo: \(message)")

    TelemetryDeck.errorOccurred(
      id: "CameraManager.capture",
      category: .thrownException,
      message: message
    )
  }
}

extension CameraManager: AVCaptureMetadataOutputObjectsDelegate {

  nonisolated func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard
      let metadataObject = metadataObjects.first,
      let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
      let stringValue = readableObject.stringValue
    else { return }

    Task {
      await onDetect(code: stringValue)
    }
  }
}

private extension CameraManager {

  func onDetect(code: String) {
    onNewBarcode?(code)
  }
}

// MARK: - SendableImage

private struct SendableImage: Sendable {
  let data: Data?
  let error: Error?
}
