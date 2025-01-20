//
//  CameraPermissionDeniedView.swift
//  Supplements
//
//  Created by Zach Radford on 2024-12-16.
//

import SwiftUI

struct CameraPermissionDeniedView: View {

  @StateObject var permissionManager = CameraPermissionManager.shared

  var body: some View {
      ZStack {
          Color.black.edgesIgnoringSafeArea(.all)

          VStack(spacing: 16) {
              Image(systemName: "camera.fill")
                  .font(.system(size: 80))
                  .foregroundColor(.gray)

              Text("Bloom requires permission to take photos.")
                  .font(.title3)
                  .fontWeight(.semibold)
                  .multilineTextAlignment(.center)
                  .foregroundColor(.gray)
                  .padding(.horizontal)

              Button {
                  permissionManager.openSettings()
              } label: {
                  Text("Open Settings")
                      .fontWeight(.bold)
                      .foregroundColor(.white)
              }
          }
      }
  }
}

#Preview {
  CameraPermissionDeniedView()
}
