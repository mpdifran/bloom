//
//  FilesImagePicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilesImagePicker: UIViewControllerRepresentable {
  @Binding var images: [UIImage]

  /// The maximum number of images that can be picked in one presentation. Zero means no limit.
  let selectionLimit: Int

  @Environment(\.dismiss) private var dismiss

  init(images: Binding<[UIImage]>, selectionLimit: Int = 1) {
    self._images = images
    self.selectionLimit = selectionLimit
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(images: $images, selectionLimit: selectionLimit) {
      dismiss()
    }
  }

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let controller = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image], asCopy: true)
    controller.delegate = context.coordinator
    controller.allowsMultipleSelection = selectionLimit != 1
    return controller
  }

  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    // No updates needed
  }

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    @Binding var images: [UIImage]
    let selectionLimit: Int
    let dismiss: () -> Void

    init(images: Binding<[UIImage]>, selectionLimit: Int, dismiss: @escaping () -> Void) {
      self._images = images
      self.selectionLimit = selectionLimit
      self.dismiss = dismiss
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      let limitedURLs = selectionLimit > 0 ? Array(urls.prefix(selectionLimit)) : urls

      // Attempt to load an image from each selected file
      images.append(contentsOf: limitedURLs.compactMap { url in
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
      })
      dismiss()
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
      dismiss()
    }
  }
}

#Preview {
  @Previewable @State var images = [UIImage]()

  PreviewEnvironment {
    FilesImagePicker(images: $images, selectionLimit: 0)
  }
}
