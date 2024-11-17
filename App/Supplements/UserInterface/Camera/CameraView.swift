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
    ZStack {
      Color.black.edgesIgnoringSafeArea(.all)

      CameraPreview(
        session: viewModel.session
      )
    }
    .task {
      await viewModel.manager.start()
    }
  }
}
