//
//  AIFoodScannerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import SwiftUI
import AppUI
import BloomModel
import AVFoundation

struct AIFoodScannerView: View {

    init() {
        self.cameraManager = CameraManager.create(with: captureSession)
    }

    @Bindable private var viewModel = AIFoodScannerViewModel()

    @State private var image: UIImage?

    @StateObject var permissionManager = CameraPermissionManager.shared

    @Environment(\.dismiss) private var dismiss

    private let cameraManager: CameraManager
    private let captureSession = AVCaptureSession()

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                scanAreaView
                    .frame(height: proxy.size.height * imageScanAspect)
                    .clipped()

                scannedItemsView
                    .background {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.background)
                            .ignoresSafeArea(edges: .bottom)
                    }
                    .padding(.top, -30)
            }
        }
        .ignoresSafeArea(edges: .top)
        .presentationCompactAdaptation(.fullScreenCover)
        .animation(.bouncy, value: image)
        .animation(.default, value: viewModel.isLoading)
        .onAppear {
            Task {
                await permissionManager.checkPermission()
                if permissionManager.permissionState == .granted {
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

private extension AIFoodScannerView {

    var imageScanAspect: CGFloat {
        if image == nil {
            return 0.6
        }
        return 0.4
    }

    @ViewBuilder
    var scanAreaView: some View {
        switch permissionManager.permissionState {
        case .granted:
            cameraView
        case .denied:
            permissionDeniedView
        case .pending:
            Rectangle()
                .fill(.green)
                .ignoresSafeArea()
                .aspectRatio(contentMode: .fit)
        }
    }

    var cameraView: some View {
        ZStack {
            CameraPreview(
                session: captureSession,
                gravity: .resizeAspectFill
            ) { focusPoint in
                Task {
                    await cameraManager.setFocus(for: focusPoint)
                }
            }

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
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

    var scannedItemsView: some View {
        VStack {
            if image == nil {
                VStack {
                    Spacer()
                    ContentUnavailableView("Scan Food", systemImage: "fork.knife")
                    Spacer()
                }
                .horizontallyCentered()
            } else if viewModel.isLoading {
                VStack {
                    Spacer()
                    CircularSpinnerView()
                        .foregroundStyle(.tint)
                    Text("Analyzing...")
                        .font(.title2)
                        .bold()
                        .fontDesign(.rounded)
                    Spacer()
                }
                .horizontallyCentered()
            } else {
                ScrollView {
                    VStack {
                        if viewModel.servings.isEmpty {
                            Spacer()
                            ContentUnavailableView("No Food Identified", systemImage: "fork.knife")
                            Spacer()
                        } else {
                            SectionTitleView("Identified Food")
                                .padding(.horizontal)
                            ForEachEnumerated(viewModel.servings) { (index, serving) in
                                AIScanFoodItemCell(foodItemServing: $viewModel.servings[index])
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }

            HStack(spacing: 6) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .bold()
                        .frame(square: 55)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.tint)
                        }
                        .foregroundStyle(.white)
                }

                if viewModel.servings.isNotEmpty {
                    Button {
                        // Log food
                    } label: {
                        Text("Log All")
                            .bold()
                            .horizontallyCentered()
                            .frame(height: 55)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.tint)
                            }
                            .foregroundStyle(.white)
                    }
                } else {
                    Button {
                        Task {
                            guard let image = await cameraManager.capture() else { return } // TODO: Throw error?

                            self.image = image
                            await viewModel.performAIFoodLog(for: image)
                        }
                    } label: {
                        Text("Scan")
                            .bold()
                            .horizontallyCentered()
                            .frame(height: 55)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.tint)
                            }
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }

    }
}

#Preview {
    AIFoodScannerView()
}
