//
//  CameraView.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

import AVFoundation
import SwiftUI

struct CameraView: View {
  let onImageCaptured: @MainActor (UIImage?) -> Void

  private let manager: CameraManager
  private let captureSession = AVCaptureSession()

  @Environment(\.dismiss) private var dismiss

  init(
    onImageCaptured: @escaping @MainActor (UIImage?) -> Void
  ) {
    manager = CameraManager.create(with: captureSession)
    self.onImageCaptured = onImageCaptured
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.black.edgesIgnoringSafeArea(.all)

      CameraPreview(
        session: captureSession
      )

      captureButton
        .padding(.bottom, 24)
    }
    .task {
      await manager.start()
    }
    .onDisappear {
      Task {
        await manager.stop()
      }
    }
  }
}

private extension CameraView {
  var captureButton: some View {
    Button {
      Task {
        let image = await manager.capture()
        await MainActor.run {
          onImageCaptured(image)
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
}
