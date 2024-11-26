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
        configureCaptureSession()

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

        captureSession.beginConfiguration()

        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .photo

        setupVideoInput()
        setupPhotoOutput()

        isInitialized = true

        // After the camera is initialized, we need to reset the zoom scale for 1x camera (0.5x is default).
        // We cannot set the zoom factor when setting up the video input initially, it must be done after.
        resetZoomScale()
    }

    func setupVideoInput() {
        do {
          // Choose the best available camera for close up focus (wider the better).
          let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
//              .builtInUltraWideCamera,
//              .builtInTelephotoCamera,
              .builtInTripleCamera,
              .builtInDualCamera,
            ],
            mediaType: .video,
            position: .back
          )
          guard let camera = discoverySession.devices.first else {
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
        guard captureSession.canAddOutput(photoOutput) else {
            print("CameraManager: Could not add photo output to session")
            return
        }

        captureSession.addOutput(photoOutput)

        photoOutput.maxPhotoDimensions = .init(width: 4032, height: 3024)
        photoOutput.maxPhotoQualityPrioritization = .quality
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
