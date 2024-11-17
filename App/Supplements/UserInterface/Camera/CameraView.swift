//
//  CameraView.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

import SwiftUI

struct CameraView: View {
  @ObservedObject var viewModel = CameraViewModel()

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.black.edgesIgnoringSafeArea(.all)

      CameraPreview(
        session: viewModel.session
      )

      captureButton
        .padding(.bottom, 24)
    }
    .task {
      await viewModel.manager.start()
    }
    .onDisappear {
      Task {
        await viewModel.manager.stop()
      }
    }
  }
}

private extension CameraView {
  var captureButton: some View {
    Button {
      viewModel.capturePressed()
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
