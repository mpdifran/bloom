//
//  CameraPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI

struct CameraPicker: UIViewControllerRepresentable {
  @Binding var image: UIImage?

  @Environment(\.dismiss) private var dismiss

  func makeCoordinator() -> Coordinator {
    Coordinator(image: $image) {
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
    @Binding var image: UIImage?
    let dismiss: () -> Void

    init(image: Binding<UIImage?>, dismiss: @escaping () -> Void) {
      self._image = image
      self.dismiss = dismiss
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      self.image = info[.originalImage] as? UIImage
      dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      dismiss()
    }
  }
}

#Preview {
  @Previewable @State var image: UIImage?

  PreviewEnvironment {
    CameraPicker(image: $image)
  }
}
