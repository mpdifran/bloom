//
//  AICameraScannerView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-07.
//

import SwiftUI
import AppUI
import AVFoundation

struct AICameraScannerView: View {
  let cameraManager: CameraManager
  let captureSession: AVCaptureSession
  @Binding var image: UIImage?
  let reset: () -> Void

  @State private var alertDetails: AlertDetails?

  @StateObject private var permissionManager = CameraPermissionManager.shared

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
        Rectangle()
          .fill(.black)
          .ignoresSafeArea()
          .aspectRatio(contentMode: .fit)
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 30))
  }
}

private extension AICameraScannerView {

  var cameraView: some View {
    ZStack {
      CameraPreview(
        session: captureSession,
        gravity: .resizeAspectFill
      ) { focusPoint in
        Task {
          await cameraManager.setFocus(for: focusPoint)
        }
      }

      if let image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(1, contentMode: .fill)

        Button {
          reset()
        } label: {
          Image(systemName: "arrow.counterclockwise")
            .bold()
            .padding(10)
            .background {
              Circle()
                .fill(.regularMaterial)
            }
        }
      }
    }
    .animation(.easeInOut, value: image)
  }
}

#Preview {
  @Previewable @State var image: UIImage?

  let captureSession = AVCaptureSession()
  let cameraManager = CameraManager.create(with: captureSession)

  AICameraScannerView(
    cameraManager: cameraManager,
    captureSession: captureSession,
    image: $image
  ) {

  }
}
