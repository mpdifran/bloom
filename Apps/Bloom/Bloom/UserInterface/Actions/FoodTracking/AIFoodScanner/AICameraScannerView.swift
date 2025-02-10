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
    ZStack {
      CameraPreview(
        cameraManager: cameraManager,
        gravity: .resizeAspectFill
      ) { focusPoint in
        Task {
          await cameraManager.setFocus(for: focusPoint)
        }
      }

      if let image {
        GeometryReader { geometry in
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(square: geometry.size.width / 4)
            .zStackAlignment(.bottomTrailing)
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var image: UIImage?

  let cameraManager = CameraManager()

  VStack {
    Spacer()
    AICameraScannerView(
      cameraManager: cameraManager,
      image: $image
    )
    Spacer()
  }
  .padding()
  .groupedBackground()
}
