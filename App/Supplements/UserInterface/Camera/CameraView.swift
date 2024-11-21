//
//  CameraView.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-16.
//

import AVFoundation
import SwiftUI

// MARK: - CameraView

struct CameraView: View {

    @Binding var capturedImage: UIImage?
    private let instructions: String
    private let aspectRatio: CGFloat

    init(
        capturedImage: Binding<UIImage?>,
        instructions: String,
        aspectRatio: CGFloat
    ) {
        self.cameraManager = CameraManager.create(with: captureSession)
        self._capturedImage = capturedImage
        self.instructions = instructions
        self.aspectRatio = aspectRatio
    }

    private let cameraManager: CameraManager
    private let captureSession = AVCaptureSession()

    @StateObject var permissionManager = CameraPermissionManager.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if permissionManager.isPermissionGranted {
                cameraView
            } else {
                permissionDeniedView
            }
        }
        .overlay {
            dismissButton
                .zStackAlignment(.topLeading)
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .onAppear {
            Task {
                await permissionManager.checkPermission()
                if permissionManager.isPermissionGranted {
                    await cameraManager.start()
                }
            }
        }
        .onDisappear {
            Task {
                await cameraManager.stop()
            }
        }
        .alert(isPresented: $permissionManager.shouldShowAlert) {
            Alert(
                title: Text("Camera Permission Required"),
                message: Text("Please allow camera access in Settings."),
                primaryButton: .default(Text("Open Settings")) {
                    permissionManager.openSettings()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
}

// MARK: Private Methods

private extension CameraView {

    var cameraView: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

          CameraPreview(
              session: captureSession
          ) { focusPoint in
            Task {
              await cameraManager.setFocus(for: focusPoint)
            }
          }

          CutoutOverlayView(aspectRatio: aspectRatio)
            .allowsHitTesting(false) // allow tapping through the overlay.

            instructionLabel
                .padding(.top, 24)
                .zStackAlignment(.top)


            captureButton
                .padding(.bottom, 24)
                .zStackAlignment(.bottom)
        }
    }

    var instructionLabel: some View {
        Text(instructions)
            .foregroundStyle(.white)
            .font(.caption)
            .bold()
            .fontDesign(.rounded)
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(10)
            .multilineTextAlignment(.center)
    }

    var captureButton: some View {
        Button {
            Task {
                let image = await cameraManager.capture()
                await MainActor.run {
                    capturedImage = image
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

    var dismissButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.white, .gray)
                .font(.title)
        }
        .frame(square: 44)
        .padding()
    }

    var permissionDeniedView: some View {
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
    CameraView(
        capturedImage: .constant(nil),
        instructions: "Position your package within the frame",
        aspectRatio: 0.8
    )
}
