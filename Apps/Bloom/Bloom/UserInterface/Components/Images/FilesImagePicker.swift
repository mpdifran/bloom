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

  /// When set, any file can be picked: images still land in `images`, and other files the chat
  /// can read land here.
  let documents: Binding<[ChatDocument]>?
  /// Set when some picked files couldn't be attached. Only used alongside `documents`.
  let error: Binding<Error?>?

  /// The maximum number of files that can be picked in one presentation. Zero means no limit.
  let selectionLimit: Int

  @Environment(\.dismiss) private var dismiss

  init(
    images: Binding<[UIImage]>,
    documents: Binding<[ChatDocument]>? = nil,
    error: Binding<Error?>? = nil,
    selectionLimit: Int = 1
  ) {
    self._images = images
    self.documents = documents
    self.error = error
    self.selectionLimit = selectionLimit
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(images: $images, documents: documents, error: error, selectionLimit: selectionLimit) {
      dismiss()
    }
  }

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let contentTypes: [UTType] = documents == nil ? [.image] : [.item]
    let controller = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
    controller.delegate = context.coordinator
    controller.allowsMultipleSelection = selectionLimit != 1
    return controller
  }

  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    // No updates needed
  }

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    @Binding var images: [UIImage]
    let documents: Binding<[ChatDocument]>?
    let error: Binding<Error?>?
    let selectionLimit: Int
    let dismiss: () -> Void

    init(
      images: Binding<[UIImage]>,
      documents: Binding<[ChatDocument]>?,
      error: Binding<Error?>?,
      selectionLimit: Int,
      dismiss: @escaping () -> Void
    ) {
      self._images = images
      self.documents = documents
      self.error = error
      self.selectionLimit = selectionLimit
      self.dismiss = dismiss
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
      let limitedURLs = selectionLimit > 0 ? Array(urls.prefix(selectionLimit)) : urls

      if let documents {
        let result = ChatAttachmentLoader.load(
          urls: limitedURLs,
          remainingCount: limitedURLs.count,
          existingDocumentBytes: documents.wrappedValue.reduce(0) { $0 + $1.data.count }
        )
        images.append(contentsOf: result.images)
        documents.wrappedValue.append(contentsOf: result.documents)
        dismiss()
        // Raised after dismissing so the alert isn't presented from the picker.
        if let attachmentError = result.error {
          error?.wrappedValue = attachmentError
        }
        return
      }

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
