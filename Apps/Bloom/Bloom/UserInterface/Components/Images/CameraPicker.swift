//
//  CameraPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI

struct CameraPicker: UIViewControllerRepresentable {
  @Binding var images: [UIImage]

  @Environment(\.dismiss) private var dismiss

  /// Whether this device can take a photo right now. Setting `.camera` as the source type when it
  /// isn't available throws, and an uncaught exception takes the app down - so callers should hide
  /// the option rather than present this.
  static var isAvailable: Bool {
    UIImagePickerController.isSourceTypeAvailable(.camera)
  }

  init(images: Binding<[UIImage]>) {
    self._images = images
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(images: $images) {
      dismiss()
    }
  }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    // Availability can change between the menu being built and this running. The library is a
    // better outcome than a crash.
    picker.sourceType = Self.isAvailable ? .camera : .photoLibrary
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    // No updates needed
  }

  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @Binding var images: [UIImage]
    let dismiss: () -> Void

    init(images: Binding<[UIImage]>, dismiss: @escaping () -> Void) {
      self._images = images
      self.dismiss = dismiss
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      if let image = info[.originalImage] as? UIImage {
        images.append(image)
      }
      dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      dismiss()
    }
  }
}

#Preview {
  @Previewable @State var images = [UIImage]()

  PreviewEnvironment {
    CameraPicker(images: $images)
  }
}
