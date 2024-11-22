//
//  CameraPreview.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

import AVFoundation
import SwiftUI

// MARK: - CameraPreview

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession
    let onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspect
        view.videoPreviewLayer.connection?.videoRotationAngle = 90

        let tapGesture = UITapGestureRecognizer(
          target: context.coordinator,
          action: #selector(context.coordinator.handleTapGesture(_:))
        )
        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) { }

    func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }

  class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
      AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
      return layer as! AVCaptureVideoPreviewLayer
    }
  }

  class Coordinator: NSObject {

    var parent: CameraPreview

    init(_ parent: CameraPreview) {
      self.parent = parent
    }

    @MainActor
    @objc
    func handleTapGesture(_ sender: UITapGestureRecognizer) {
      let location = sender.location(in: sender.view)
      parent.onTap(location)
    }
  }
}


