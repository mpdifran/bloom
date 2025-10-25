//
//  MagicScannerReviewCardView.swift
//  Bloom
//
//  Created by Claude on 2025-10-25.
//

import SwiftUI
import BloomUI
import DataContainer

struct MagicScannerReviewCardView: View {
  let image: UIImage
  @Binding var contextText: String
  let onSave: () -> Void
  let onRetake: () -> Void

  @State private var imageWidth: CGFloat = 300

  @Environment(\.dismiss) private var dismiss
  @FocusState private var isContextFieldFocused: Bool

  var body: some View {
    CardView {
      VStack {
        FoodItemLogPickerHeader()

        if let squareImage = image.croppedToSquare() {
          Image(uiImage: squareImage)
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .frame(width: imageWidth)
        }

        TextField(
          "",
          text: $contextText,
          prompt: Text("Add extra details about your meal."),
          axis: .vertical
        )
        .focused($isContextFieldFocused)
        .font(.title2)
        .fontDesign(.rounded)
        .lineLimit(3...6)
        .bold()
        .multilineTextAlignment(.leading)
        .cardContainer(fill: .background.secondary)

        Button {

        } label: {
          Text("Save")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      }
      .readViewSize { proxy in
        imageWidth = proxy.size.width
      }
      .padding()
    }
  }
}

#Preview {
  @Previewable @State var contextText: String = ""

  // Create a sample square image
  let size = CGSize(width: 400, height: 400)
  let renderer = UIGraphicsImageRenderer(size: size)
  let sampleImage = renderer.image { context in
    UIColor.systemBlue.setFill()
    context.fill(CGRect(origin: .zero, size: size))
  }

  PreviewEnvironment {
    PreviewSheetPresent {
      MagicScannerReviewCardView(
        image: sampleImage,
        contextText: $contextText,
        onSave: { print("Save tapped") },
        onRetake: { print("Retake tapped") }
      )
    }
  }
}
