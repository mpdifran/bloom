//
//  DataScannerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-10.
//

import SwiftUI
import VisionKit

struct DataScannerView: UIViewControllerRepresentable {
    @Binding var shouldCapturePhoto: Bool
    @Binding var capturedPhoto: IdentifiableImage?
    @Binding var recognizedItems: [RecognizedItem]
    let recognizedDataType: DataScannerViewController.RecognizedDataType

    var scannerAvailable: Bool {
        DataScannerViewController.isSupported &&
        DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [recognizedDataType],
            qualityLevel: .fast,
            isHighFrameRateTrackingEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if scannerAvailable {
            do {
                if !uiViewController.isScanning {
                    print("Attempting to start scanning")
                    try uiViewController.startScanning()
                    print("Started scanning")
                } else {
                    print("Already scanning")
                }
            } catch {
                print(error)
            }
        } else {
            print("Scanner not available")
        }
        if shouldCapturePhoto {
            capturePhoto(dataScannerVC: uiViewController)
        }
    }

    private func capturePhoto(dataScannerVC: DataScannerViewController) {
        Task { @MainActor in
            do {
                let photo = try await dataScannerVC.capturePhoto()
                self.capturedPhoto = .init(image: photo)
            } catch {
                print(error.localizedDescription)
            }
            self.shouldCapturePhoto = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedItems: $recognizedItems)
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
}

extension DataScannerView {
    class Coordinator: NSObject, DataScannerViewControllerDelegate {

        @Binding var recognizedItems: [RecognizedItem]

        init(recognizedItems: Binding<[RecognizedItem]>) {
            self._recognizedItems = recognizedItems
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            print("didTapOn \(item)")
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            recognizedItems.append(contentsOf: addedItems)
            print("didAddItems \(addedItems)")
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            self.recognizedItems = recognizedItems.filter { item in
                !removedItems.contains(where: {$0.id == item.id })
            }
            print("didRemovedItems \(removedItems)")
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            print("became unavailable with error \(error.localizedDescription)")
            // TODO: Dismiss the view
        }
    }
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
