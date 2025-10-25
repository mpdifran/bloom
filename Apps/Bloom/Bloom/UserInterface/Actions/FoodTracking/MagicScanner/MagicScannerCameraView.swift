//
//  MagicScannerCameraView.swift
//  Bloom
//
//  Created by Claude on 2025-10-25.
//

import SFSafeSymbols
import AppUI
import AVFoundation
import PhotosUI
import SwiftUI
import DataContainer
import CoreHealth
import BloomModel

// MARK: - MagicScannerCameraView

struct MagicScannerCameraView: View {

  @State private var capturedImage: UIImage?
  @State private var contextText: String = ""
  @State private var showReviewSheet = false
  @State private var selectedPhotoItem: PhotosPickerItem?

  private let cameraManager = CameraManager()

  @State private var alertDetails: AlertDetails?

  @StateObject var permissionManager = CameraPermissionManager.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
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
          // Just a black screen.
          Color.black.edgesIgnoringSafeArea(.all)
        }
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
        ToolbarItem(placement: .principal) {
          if #available(iOS 26, *) {
            FoodItemLogPickerHeader()
              .padding(.horizontal, 20)
              .glassEffect()
          } else {
            FoodItemLogPickerHeader()
          }
        }
        ToolbarItem(placement: .primaryAction) {
          galleryButton
        }
      }
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .onAppear {
      Task {
        await permissionManager.checkPermission()
        if permissionManager.permissionState == .granted {
          cameraManager.start()
        }
      }
    }
    .onDisappear {
      cameraManager.stop()
    }
    .alert(alertDetails: $alertDetails)
    .sheet(isPresented: $showReviewSheet) {
      if let capturedImage {
        MagicScannerReviewCardView(
          image: capturedImage,
          contextText: $contextText,
          onDismissAll: {
            showReviewSheet = false
            dismiss()
          }
        )
      }
    }
  }
}

// MARK: Private Methods

private extension MagicScannerCameraView {

  var cameraView: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()

      CameraPreview(
        cameraManager: cameraManager,
        gravity: .resizeAspectFill
      ) { focusPoint in
        Task {
          await cameraManager.setFocus(for: focusPoint)
        }
      }
      .ignoresSafeArea()

      captureButton
        .padding(.bottom, 24)
        .zStackAlignment(.bottom)
    }
  }

  var captureButton: some View {
    Button {
      Task {
        let image = await cameraManager.capture()
        await MainActor.run {
          capturedImage = image
          showReviewSheet = true
        }
      }
    } label: {
      if #available(iOS 26, *) {
        Circle()
          .frame(width: 70, height: 70, alignment: .center)
          .glassEffect(in: Circle())
          .overlay(
            Circle()
              .stroke(Color.white.opacity(0.8), lineWidth: 2)
              .frame(width: 59, height: 59, alignment: .center)
          )
      } else {
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
    .buttonStyle(.plain)
  }

  var galleryButton: some View {
    PhotosPicker(
      selection: $selectedPhotoItem,
      matching: .images
    ) {
      Image(systemSymbol: .photoOnRectangleAngled)
    }
    .buttonStyle(.plain)
    .task(id: selectedPhotoItem) {
      guard
        let selectedPhotoItem,
        let image = try? await selectedPhotoItem.loadTransferable(type: Data.self),
        let uiImage = UIImage(data: image)
      else {
        return
      }
      capturedImage = uiImage
      showReviewSheet = true
    }
  }
}

#Preview {
  PreviewEnvironment {
    MagicScannerCameraView()
  }
}
