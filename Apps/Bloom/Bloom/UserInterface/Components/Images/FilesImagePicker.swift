//
//  FilesImagePicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilesImagePicker: UIViewControllerRepresentable {
  @Binding var image: UIImage?

  @Environment(\.dismiss) private var dismiss

  func makeCoordinator() -> Coordinator {
    Coordinator(image: $image) {
      dismiss()
    }
  }

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let controller = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image], asCopy: true)
    controller.delegate = context.coordinator
    controller.allowsMultipleSelection = false
    return controller
  }

  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    // No updates needed
  }

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    @Binding var image: UIImage?
    let dismiss: () -> Void

    init(image: Binding<UIImage?>, dismiss: @escaping () -> Void) {
      self._image = image
      self.dismiss = dismiss
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      guard let url = urls.first else { return }

      // Attempt to load an image from the selected file
      if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
        self.image = image
      }
      dismiss()
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
      dismiss()
    }
  }
}

#Preview {
  @Previewable @State var image: UIImage?

  PreviewEnvironment {
    FilesImagePicker(image: $image)
  }
}
