//
//  PhotoLibraryPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI
import PhotosUI

struct PhotoLibraryPicker: UIViewControllerRepresentable {
  @Binding var images: [UIImage]

  /// The maximum number of images that can be picked in one presentation. Zero means no limit.
  let selectionLimit: Int

  @Environment(\.dismiss) private var dismiss

  init(images: Binding<[UIImage]>, selectionLimit: Int = 1) {
    self._images = images
    self.selectionLimit = selectionLimit
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(images: $images) {
      dismiss()
    }
  }

  func makeUIViewController(context: Context) -> PHPickerViewController {
    var configuration = PHPickerConfiguration()
    configuration.filter = .images
    configuration.selectionLimit = selectionLimit

    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    // No updates needed
  }

  class Coordinator: NSObject, PHPickerViewControllerDelegate {
    @Binding var images: [UIImage]
    let dismiss: () -> Void

    init(images: Binding<[UIImage]>, dismiss: @escaping () -> Void) {
      self._images = images
      self.dismiss = dismiss
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      Task { @MainActor in
        // Loaded in order so the previews match the order they were picked in.
        var pickedImages = [UIImage]()
        for result in results {
          if let image = await result.itemProvider.loadImage() {
            pickedImages.append(image)
          }
        }
        images.append(contentsOf: pickedImages)
        dismiss()
      }
    }
  }
}

#Preview {
  @Previewable @State var images = [UIImage]()

  PreviewEnvironment {
    PhotoLibraryPicker(images: $images, selectionLimit: 0)
  }
}
