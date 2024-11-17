//
//  Untitled.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

import AVFoundation
import SwiftUI

struct CameraPreview: UIViewRepresentable {

  let session: AVCaptureSession

  func makeUIView(context: Context) -> VideoPreviewView {
    let view = VideoPreviewView()
    view.backgroundColor = .black
    view.videoPreviewLayer.session = session
    view.videoPreviewLayer.videoGravity = .resizeAspectFill
    view.videoPreviewLayer.connection?.videoRotationAngle = 90

    return view
  }

  public func updateUIView(_ uiView: VideoPreviewView, context: Context) { }

  class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
       AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
      return layer as! AVCaptureVideoPreviewLayer
    }
  }
}
