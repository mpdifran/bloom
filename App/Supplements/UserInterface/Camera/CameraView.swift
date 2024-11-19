//
//  CameraView.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

import AVFoundation
import SwiftUI

// MARK: - CameraView

struct CameraView: View {
  private let cameraManager: CameraManager
  private let captureSession = AVCaptureSession()

  @StateObject var permissionManager = CameraPermissionManager.shared

  @Binding var capturedImage: UIImage?

  @Environment(\.dismiss) private var dismiss

  init(capturedImage: Binding<UIImage?>) {
    cameraManager = CameraManager.create(with: captureSession)
    _capturedImage = capturedImage
  }

  var body: some View {
    Group {
      if permissionManager.isPermissionGranted {
        cameraView
      } else {
        permissionDeniedView
      }
    }
    .onAppear {
      Task {
        await permissionManager.checkPermission()
        if permissionManager.isPermissionGranted {
          await cameraManager.start()
        }
      }
    }
    .onDisappear {
      Task {
        await cameraManager.stop()
      }
    }
    .alert(isPresented: $permissionManager.shouldShowAlert) {
      Alert(
        title: Text("Camera Permission Required"),
        message: Text("Please allow camera access in Settings."),
        primaryButton: .default(Text("Open Settings")) {
          permissionManager.openSettings()
        },
        secondaryButton: .cancel(Text("Cancel"))
      )
    }
  }
}

// MARK: Private Methods

private extension CameraView {
  var cameraView: some View {
    ZStack {
      Color.black.edgesIgnoringSafeArea(.all)

      CameraPreview(
        session: captureSession
      )

      CutoutOverlayView()

      instructionLabel
        .padding(.top, 24)
        .zStackAlignment(.top)

      captureButton
        .padding(.bottom, 24)
        .zStackAlignment(.bottom)
    }
  }

  var instructionLabel: some View {
    Text("Please position your package within the frame")
      .foregroundStyle(.white)
      .font(.caption)
      .fontDesign(.rounded)
      .padding()
      .background(Color.black.opacity(0.6))
      .cornerRadius(10)
      .multilineTextAlignment(.center)
  }

  var captureButton: some View {
    Button {
      Task {
        let image = await cameraManager.capture()
        await MainActor.run {
          capturedImage = image
          dismiss()
        }
      }
    } label: {
      Circle()
        .foregroundColor(.white)
        .frame(width: 70, height: 70, alignment: .center)
        .overlay(
          Circle()
            .stroke(Color.black.opacity(0.8), lineWidth: 2)
            .frame(width: 59, height: 59, alignment: .center)
        )
    }
  }

  var permissionDeniedView: some View {
    ZStack {
      Color.black.edgesIgnoringSafeArea(.all)

      VStack(spacing: 16) {
        Image(systemName: "camera.fill")
          .font(.system(size: 80))
          .foregroundColor(.gray)

        Text("Bloom requires permission to take photos.")
          .font(.title3)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)
          .foregroundColor(.gray)
          .padding(.horizontal)

        Button {
          permissionManager.openSettings()
        } label: {
          Text("Open Settings")
            .fontWeight(.bold)
            .foregroundColor(.white)
        }
      }
    }
  }
}

// MARK: - CutoutOverlayView

struct CutoutOverlayView: View {
  private let widthPercentage: CGFloat = 0.6
  private let heightPercentage: CGFloat = 0.3

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.opacity(0.6)

        Rectangle()
          .frame(
            width: geometry.size.width * widthPercentage,
            height: geometry.size.height * heightPercentage
          )
          .cornerRadius(20)
          .blendMode(.destinationOut)
      }
      .compositingGroup()
      .edgesIgnoringSafeArea(.all)
    }
  }
}
