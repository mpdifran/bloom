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
