//
//  CameraView.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

import SFSafeSymbols
import AppUI
import AVFoundation
import PhotosUI
import SwiftUI

// MARK: - CameraView

struct CameraView: View {

  @Binding private var capturedImage: UIImage?
  private let instructions: String
  private let aspectRatio: CGFloat

  @State private var selectedImage: PhotosPickerItem?

  private let cameraManager = CameraManager()

  @State private var alertDetails: AlertDetails?

  @StateObject var permissionManager = CameraPermissionManager.shared

  @Environment(\.dismiss) private var dismiss

  init(
    capturedImage: Binding<UIImage?>,
    instructions: String,
    aspectRatio: CGFloat
  ) {
    self._capturedImage = capturedImage
    self.instructions = instructions
    self.aspectRatio = aspectRatio
  }

  var body: some View {
    Group {
      switch permissionManager.permissionState {
      case .granted:
        cameraView
      case .denied:
        CameraPermissionDeniedView()
          .onAppear {
            alertDetails = permissionManager.permissionAlert
          }
      case .pending:
        // Just a black screen.
        Color.black.edgesIgnoringSafeArea(.all)
      }
    }
    .overlay {
      dismissButton
        .zStackAlignment(.topLeading)
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .onAppear {
      Task {
        await permissionManager.checkPermission()
        if permissionManager.permissionState == .granted {
          cameraManager.start()
        }
      }
    }
    .onDisappear {
      Task {
        cameraManager.stop()
      }
    }
    .alert(alertDetails: $alertDetails)
  }
}

// MARK: Private Methods

private extension CameraView {

  var cameraView: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()

      CameraPreview(cameraManager: cameraManager) { focusPoint in
        Task {
          await cameraManager.setFocus(for: focusPoint)
        }
      }

      CutoutOverlayView(aspectRatio: aspectRatio)
        .allowsHitTesting(false) // allow tapping through the overlay.

      instructionLabel
        .padding(.top, 24)
        .zStackAlignment(.top)


      captureButton
        .padding(.bottom, 24)
        .zStackAlignment(.bottom)

      pickerButton
        .padding(.bottom, 24)
        .padding(.leading)
        .zStackAlignment(.bottomLeading)

    }
  }

  var instructionLabel: some View {
    Text(instructions)
      .foregroundStyle(.white)
      .font(.caption)
      .bold()
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

  var pickerButton: some View {
    PhotosPicker(
      selection: $selectedImage,
      matching: .images
    ) {
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.secondary)
        .frame(width: 70, height: 70)
        .overlay(
          VStack {
            Image(systemSymbol: .photoOnRectangleAngled)
              .font(.system(size: 20))
            Text("Library")
              .font(.caption)
          }
        )
    }
    .task(id: selectedImage) {
      guard
        let selectedImage,
        let image = try? await selectedImage.loadTransferable(type: Data.self),
        let uiImage = UIImage(data: image)
      else {
        return
      }
      capturedImage = uiImage
      dismiss()
    }
  }

  var dismissButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemSymbol: .xmarkCircleFill)
        .foregroundStyle(.white, .gray)
        .font(.title)
    }
    .frame(square: 44)
    .padding()
  }
}

#Preview {
  CameraView(
    capturedImage: .constant(nil),
    instructions: "Position your package within the frame",
    aspectRatio: 0.8
  )
}
