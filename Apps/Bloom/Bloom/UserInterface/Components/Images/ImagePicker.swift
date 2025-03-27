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
    ImagePicker(image: $image, presentedSheet: $presentedSheet) {
      Text("Pick an Image")
    }
  }
  .sheet($presentedSheet)
}
