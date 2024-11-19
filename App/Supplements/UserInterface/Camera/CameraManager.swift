//
//  CameraManager.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

@preconcurrency import AVFoundation
import CoreImage
import UIKit

// MARK: - CameraManager

final actor CameraManager: NSObject {

  private var isInitialized = false
  private var capturedImageContinuation: CheckedContinuation<UIImage?, Never>?
  private var deviceInput: AVCaptureDeviceInput?

  private let photoOutput = AVCapturePhotoOutput()
  private let captureSession: AVCaptureSession

  private init(_ session: AVCaptureSession) {
    captureSession = session
  }

  static func create(with session: AVCaptureSession) -> CameraManager {
    CameraManager(session)
  }
}

// MARK: Public Methods

extension CameraManager {
  func start() async {
    await configureCaptureSession()

    captureSession.startRunning()
  }

  func stop() async {
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

      photoSettings.maxPhotoDimensions = .init(width: 4032, height: 3024)
      photoSettings.photoQualityPrioritization = .balanced

      photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
  }
}

// MARK: Private Methods

private extension CameraManager {
  func configureCaptureSession() async {
    guard !isInitialized else { return }

    captureSession.beginConfiguration()

    defer { captureSession.commitConfiguration() }

    captureSession.sessionPreset = .photo

    await setupVideoInput()
    await setupPhotoOutput()

    isInitialized = true
  }

  func setupVideoInput() async {
    do {
      guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
        return
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

  func setupPhotoOutput() async {
    guard captureSession.canAddOutput(photoOutput) else {
      print("CameraManager: Could not add photo output to session")
      return
    }

    captureSession.addOutput(photoOutput)

    photoOutput.maxPhotoDimensions = .init(width: 4032, height: 3024)
    photoOutput.maxPhotoQualityPrioritization = .quality
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
      print("CameraManager: Error capturing photo: \(error)")
      capturedImageContinuation?.resume(returning: nil)
      capturedImageContinuation = nil
      return
    }

    if let imageData = sendableImage.data,
       let image = UIImage(data: imageData)
    {
      capturedImageContinuation?.resume(returning: image)
    } else {
      capturedImageContinuation?.resume(returning: nil)
    }
  }
}

// MARK: - SendableImage

private struct SendableImage: Sendable {
  let data: Data?
  let error: Error?
}
