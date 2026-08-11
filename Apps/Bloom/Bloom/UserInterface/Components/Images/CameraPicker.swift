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
    picker.sourceType = .camera
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
