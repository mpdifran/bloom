//
//  ImagePicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI
import AppUI
import SFSafeSymbols

struct ImagePicker<Label>: View where Label: View {
  @Binding var image: UIImage?
  @Binding var presentedSheet: AnyView?
  let labelBuilder: () -> Label

  init(
    image: Binding<UIImage?>,
    presentedSheet: Binding<AnyView?>,
    @ViewBuilder labelBuilder: @escaping () -> Label
  ) {
    self._image = image
    self._presentedSheet = presentedSheet
    self.labelBuilder = labelBuilder
  }

  var body: some View {
    Menu {
      Button("Camera", systemSymbol: .camera) {
        presentedSheet = CameraPicker(image: $image).asAny
      }
      Button("Photo Library", systemSymbol: .photo) {
        presentedSheet = PhotoLibraryPicker(image: $image).asAny
      }
      Button("Files", systemSymbol: .folder) {
        presentedSheet = FilesImagePicker(image: $image).asAny
      }

      Divider()

      if image != nil {
        Button("Delete", systemSymbol: .trash, role: .destructive) {
          self.image = nil
        }
      }
    } label: {
      labelBuilder()
    }
    .buttonStyle(.plain)
  }
}

#Preview {
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
