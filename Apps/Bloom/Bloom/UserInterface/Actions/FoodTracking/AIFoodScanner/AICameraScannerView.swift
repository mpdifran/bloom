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

  @State private var alertDetails: AlertDetails?

  @StateObject private var permissionManager = CameraPermissionManager.shared

  var body: some View {
    VStack {
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
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 30))
  }
}

private extension AICameraScannerView {

  @ViewBuilder
  var cameraView: some View {
    if let image {
      GeometryReader { geometry in
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(square: geometry.size.width)
      }
    } else {
      CameraPreview(
        session: captureSession,
        gravity: .resizeAspectFill
      ) { focusPoint in
        Task {
          await cameraManager.setFocus(for: focusPoint)
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var image: UIImage?

  let captureSession = AVCaptureSession()
  let cameraManager = CameraManager.create(with: captureSession)

  VStack {
    Spacer()
    AICameraScannerView(
      cameraManager: cameraManager,
      captureSession: captureSession,
      image: $image
    )
    Spacer()
  }
  .padding()
  .groupedBackground()
}
