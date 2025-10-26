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

  @State private var cameraCaptureToggle = false
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
          Color.black.edgesIgnoringSafeArea(.all)
            .overlay {
              viewfinderView
            }
            .ignoresSafeArea()
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

      CameraPreview(
        cameraManager: cameraManager,
        gravity: .resizeAspectFill
      ) { focusPoint in
        Task {
          await cameraManager.setFocus(for: focusPoint)
        }
      }

      viewfinderView

      captureButton
        .padding(.bottom, 24)
        .zStackAlignment(.bottom)
    }
    .ignoresSafeArea()
  }

  var viewfinderView: some View {
    ViewfinderCornerBracketsShape(
      bracketLengthRatio: 0.3,
      cornerRadius: 20
    )
    .stroke(.thickMaterial, style: StrokeStyle(lineWidth: 10, lineCap: .round))
    .aspectRatio(1, contentMode: .fit)
    .padding(30)
    .preferredColorScheme(.light)
  }

  var captureButton: some View {
    Button {
      Task {
        cameraCaptureToggle.toggle()
        let image = await cameraManager.capture()
        cameraCaptureToggle.toggle()
        await MainActor.run {
          capturedImage = image
          showReviewSheet = true
        }
      }
    } label: {
      if #available(iOS 26, *) {
        Circle()
          .frame(width: 80, height: 80, alignment: .center)
          .glassEffect(.clear, in: Circle())
          .overlay(
            Circle()
              .stroke(Color.white.opacity(0.8), lineWidth: 2)
              .frame(width: 69, height: 69, alignment: .center)
          )
      } else {
        Circle()
          .foregroundColor(.white)
          .frame(width: 80, height: 80, alignment: .center)
          .overlay(
            Circle()
              .stroke(Color.black.opacity(0.8), lineWidth: 2)
              .frame(width: 69, height: 69, alignment: .center)
          )
      }
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.impact, trigger: cameraCaptureToggle)
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
