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
import TelemetryDeck

// MARK: - MagicScannerCameraView

struct MagicScannerCameraView: View {

  let performDismiss: (() -> Void)?

  init(performDismiss: (() -> Void)? = nil) {
    self.performDismiss = performDismiss
  }

  @State private var capturedImage: UIImage?
  @State private var contextText: String = ""
  @State private var showReviewSheet = false
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var showPhotoPicker = false
  @State private var mockImage: UIImage?
  @State private var mockPhotoItem: PhotosPickerItem?

  private let cameraManager = CameraManager()

  @State private var cameraCaptureToggle = false
  @State private var alertDetails: AlertDetails?

  @StateObject var permissionManager = CameraPermissionManager.shared

  @AppStorage(.FeatureFlag.mockMagicScanner) private var mockMagicScanner = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if mockMagicScanner {
          mockCameraView
        } else {
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
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
        ToolbarItem(placement: .principal) {
          FoodItemLogPickerHeader()
              .padding(.horizontal, 20)
              .glassEffect()
        }
        ToolbarItem(placement: .primaryAction) {
          galleryButton
        }
      }
    }
    // Presented as a sheet, deliberately. As of iOS 27 a photo picker presented from a full screen
    // presentation - a fullScreenCover, or a sheet using .presentationCompactAdaptation - is torn
    // down immediately without its binding ever flipping back, so the gallery silently did nothing.
    // These modifiers make the sheet fill the screen as closely as a sheet can.
    .presentationDetents([.large])
    .presentationCornerRadius(0)
    .presentationDragIndicator(.hidden)
    .presentationBackgroundInteraction(.disabled)
    .onAppear {
      Task {
        if !mockMagicScanner {
          await permissionManager.checkPermission()
          if permissionManager.permissionState == .granted {
            cameraManager.start()
          }
        }
      }
    }
    .onDisappear {
      if !mockMagicScanner {
        cameraManager.stop()
      }
    }
    .photosPicker(
      isPresented: $showPhotoPicker,
      selection: $selectedPhotoItem,
      matching: .images
    )
    .task(id: selectedPhotoItem) {
      guard
        let selectedPhotoItem,
        let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
        let uiImage = UIImage(data: data)
      else {
        return
      }

      capturedImage = uiImage
      showReviewSheet = true
    }
    .task(id: mockPhotoItem) {
      guard
        let mockPhotoItem,
        let image = try? await mockPhotoItem.loadTransferable(type: Data.self),
        let uiImage = UIImage(data: image)
      else {
        return
      }
      mockImage = uiImage
      capturedImage = uiImage
      showReviewSheet = true
    }
    .alert(alertDetails: $alertDetails)
    .sheet(isPresented: $showReviewSheet) {
      if let capturedImage {
        MagicScannerReviewCardView(
          image: capturedImage,
          contextText: $contextText,
          performDismiss: {
            if let performDismiss {
              performDismiss()
            } else {
              dismiss()
            }
          }
        )
      }
    }
  }
}

// MARK: Private Methods

private extension MagicScannerCameraView {

  var mockCameraView: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()
        .overlay {
          if let mockImage {
            PhotosPicker(
              selection: $mockPhotoItem,
              matching: .images
            ) {
              Image(uiImage: mockImage)
                .resizable()
                .scaledToFill()
            }
            .buttonStyle(.plain)
          }
        }

      viewfinderView
        .ignoresSafeArea()

      if mockImage == nil {
        PhotosPicker(
          selection: $mockPhotoItem,
          matching: .images
        ) {
          Label("Select Photo", systemSymbol: .photoOnRectangleAngled)
            .font(.title2)
            .bold()
            .foregroundStyle(.white)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.bottom, 24)
        .zStackAlignment(.bottom)
      }
    }
    .ignoresSafeArea()
  }

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
          // A failed capture used to present the review sheet anyway, which rendered empty and
          // dismissed itself - looking like the feature had quietly died.
          guard let image else {
            alertDetails = captureFailedAlert
            return
          }

          capturedImage = image
          showReviewSheet = true
        }
      }
    } label: {
        Circle()
          .frame(width: 80, height: 80, alignment: .center)
          .glassEffect(.clear, in: Circle())
          .overlay(
            Circle()
              .stroke(Color.white.opacity(0.8), lineWidth: 2)
              .frame(width: 69, height: 69, alignment: .center)
          )
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.impact, trigger: cameraCaptureToggle)
  }

  var captureFailedAlert: AlertDetails {
    AlertDetails(
      title: "Couldn't Take Photo",
      message: "Something went wrong with the camera. Please try again.",
      buttons: [
        AlertDetails.Button(title: "OK", role: .cancel) { }
      ]
    )
  }

  /// A plain button; the picker itself is presented from the root via `.photosPicker(isPresented:)`
  /// so its presentation and the task that consumes its selection sit in the main view subtree.
  var galleryButton: some View {
    Button {
      showPhotoPicker = true
    } label: {
      Image(systemSymbol: .photoOnRectangleAngled)
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  PreviewEnvironment {
    MagicScannerCameraView()
  }
}
