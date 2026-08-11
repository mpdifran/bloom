//
//  ImagePicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI
import SFSafeSymbols

struct ImagePicker<Label>: View where Label: View {
  @Binding var images: [UIImage]
  @Binding var presentedSheet: AnyView?

  /// The maximum number of images that can be held at once. Zero means no limit.
  let maxImageCount: Int
  let labelBuilder: () -> Label

  init(
    images: Binding<[UIImage]>,
    presentedSheet: Binding<AnyView?>,
    maxImageCount: Int = 0,
    @ViewBuilder labelBuilder: @escaping () -> Label
  ) {
    self._images = images
    self._presentedSheet = presentedSheet
    self.maxImageCount = maxImageCount
    self.labelBuilder = labelBuilder
  }

  init(
    image: Binding<UIImage?>,
    presentedSheet: Binding<AnyView?>,
    @ViewBuilder labelBuilder: @escaping () -> Label
  ) {
    self.init(
      images: image.asImageArray,
      presentedSheet: presentedSheet,
      maxImageCount: 1,
      labelBuilder: labelBuilder
    )
  }

  var body: some View {
    Menu {
      Button("Camera", systemSymbol: .camera) {
        presentedSheet = CameraPicker(images: pickerBinding).asAny
      }
      .disabled(isAtCapacity)

      Button("Photo Library", systemSymbol: .photo) {
        presentedSheet = PhotoLibraryPicker(images: pickerBinding, selectionLimit: remainingCount).asAny
      }
      .disabled(isAtCapacity)

      Button("Files", systemSymbol: .folder) {
        presentedSheet = FilesImagePicker(images: pickerBinding, selectionLimit: remainingCount).asAny
      }
      .disabled(isAtCapacity)

      Divider()

      if !images.isEmpty {
        Button(deleteTitle, systemSymbol: .trash, role: .destructive) {
          self.images = []
        }
      }
    } label: {
      labelBuilder()
    }
    .buttonStyle(.plain)
  }
}

private extension ImagePicker {

  /// Single-image pickers replace what's there rather than filling up, so they're never at capacity.
  var isAtCapacity: Bool {
    maxImageCount > 1 && images.count >= maxImageCount
  }

  /// How many more images may be picked, or zero (no limit) when unbounded.
  var remainingCount: Int {
    guard maxImageCount > 0 else { return 0 }
    return max(1, maxImageCount - images.count)
  }

  var deleteTitle: String {
    images.count > 1 ? "Delete All" : "Delete"
  }

  /// When only a single image is allowed, picking a new one replaces the existing one.
  var pickerBinding: Binding<[UIImage]> {
    guard maxImageCount == 1 else { return $images }
    return Binding {
      []
    } set: { newImages in
      guard let image = newImages.last else { return }
      images = [image]
    }
  }
}

extension Binding where Value == UIImage? {

  /// Bridges a single optional image to the array-based picker API.
  var asImageArray: Binding<[UIImage]> {
    Binding<[UIImage]> {
      wrappedValue.map { [$0] } ?? []
    } set: { newImages in
      wrappedValue = newImages.last
    }
  }
}

extension NSItemProvider {

  /// Async wrapper around `loadObject(ofClass:)` for images. Returns nil if the item can't be loaded.
  func loadImage() async -> UIImage? {
    guard canLoadObject(ofClass: UIImage.self) else { return nil }

    return await withCheckedContinuation { continuation in
      loadObject(ofClass: UIImage.self) { object, _ in
        continuation.resume(returning: object as? UIImage)
      }
    }
  }
}

#Preview("Single Image") {
  @Previewable @State var image: UIImage?
  @Previewable @State var presentedSheet: AnyView?

  PreviewEnvironment {
    if let image {
      Image(uiImage: image)
        .resizable()
        .frame(square: 200)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    } else {
      RoundedRectangle(cornerRadius: 26)
        .fill(.fill)
        .frame(square: 200)
    }

    ImagePicker(image: $image, presentedSheet: $presentedSheet) {
      Text("Pick an Image")
        .frame(height: 50)
        .bold()
    }
  }
  .sheet($presentedSheet)
}

#Preview("Multiple Images") {
  @Previewable @State var images = [UIImage]()
  @Previewable @State var presentedSheet: AnyView?

  PreviewEnvironment {
    ScrollView(.horizontal) {
      HStack {
        ForEach(Array(images.enumerated()), id: \.offset) { _, image in
          Image(uiImage: image)
            .resizable()
            .frame(square: 100)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
      }
    }

    ImagePicker(images: $images, presentedSheet: $presentedSheet, maxImageCount: 10) {
      Text("Pick Images")
        .frame(height: 50)
        .bold()
    }
  }
  .sheet($presentedSheet)
}
