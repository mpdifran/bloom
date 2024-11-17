//
//  CameraManager.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

@preconcurrency import AVFoundation
import CoreImage
import UIKit

actor CameraManager: NSObject, ObservableObject {

  enum Status {
    case configured
    case unConfigured
    case unAuthorized
    case failed
  }

  @Published var status: Status = .unConfigured
  @Published var capturedImage: UIImage? = nil

  private let photoOutput = AVCapturePhotoOutput()
  private var deviceInput: AVCaptureDeviceInput?

  private let captureSession: AVCaptureSession

  private init(_ session: AVCaptureSession) {
    captureSession = session
  }

  static func create(with session: AVCaptureSession) -> CameraManager {
    CameraManager(session)
  }
}

extension CameraManager {
  func start() async {
    guard await checkAuthorization() else {
      print("Camera access not authorized")
      return
    }
    await configureCaptureSession()

    captureSession.startRunning()
  }

  func stop() async {
    guard captureSession.isRunning else { return }

    captureSession.stopRunning()
  }

  func capture() async {
    var photoSettings = AVCapturePhotoSettings()

    if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
      photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
    }

    photoSettings.maxPhotoDimensions = .init(width: 4032, height: 3024)
    photoSettings.photoQualityPrioritization = .quality

    photoOutput.capturePhoto(with: photoSettings, delegate: self)
  }
}

private extension CameraManager {
  func checkAuthorization() async -> Bool {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      print("Camera access authorized.")
      return true
    case .notDetermined:
      print("Camera access not determined.")
      return await AVCaptureDevice.requestAccess(for: .video)
    case .denied:
      print("Camera access denied.")
      return false
    case .restricted:
      print("Camera library access restricted.")
      return false
    @unknown default:
      return false
    }
  }

  func configureCaptureSession() async {
    guard status == .unConfigured else { return }

    captureSession.beginConfiguration()

    defer { captureSession.commitConfiguration() }

    captureSession.sessionPreset = .photo

    await setupVideoInput()
    await setupPhotoOutput()

    status = .configured
  }

  func setupVideoInput() async {
    do {
      guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
        status = .unConfigured
        return
      }

      let videoInput = try AVCaptureDeviceInput(device: camera)

      guard captureSession.canAddInput(videoInput) else {
        print("CameraManager: Could not add video input to session")
        status = .failed
        return
      }

      captureSession.addInput(videoInput)
      deviceInput = videoInput
    } catch {
      print("CameraManager: Could not create video input: \(error)")
      status = .failed
    }
  }

  func setupPhotoOutput() async {
    guard captureSession.canAddOutput(photoOutput) else {
      print("CameraManager: Could not add photo output to session")
      status = .failed
      return
    }

    captureSession.addOutput(photoOutput)

    photoOutput.maxPhotoDimensions = .init(width: 4032, height: 3024)
    photoOutput.maxPhotoQualityPrioritization = .quality
  }

  func updateCapturedImage(_ image: UIImage) {
    self.capturedImage = image
  }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
  nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error {
      print("CameraManager: \(error.localizedDescription)")
      return
    }

    if
      let imageData = photo.fileDataRepresentation(),
        let capturedImage = UIImage(data: imageData) {
      Task {
        await updateCapturedImage(capturedImage)
      }
    } else {
      print("CameraManager: Image could not be fetched.")
    }
  }
}
