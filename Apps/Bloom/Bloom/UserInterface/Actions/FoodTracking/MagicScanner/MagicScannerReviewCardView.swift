//
//  MagicScannerReviewCardView.swift
//  Bloom
//
//  Created by Claude on 2025-10-25.
//

import SwiftUI
import BloomUI
import DataContainer
import CoreHealth
import BloomModel
import CoreNetwork
import AppUI

struct MagicScannerReviewCardView: View {
  let image: UIImage
  @Binding var contextText: String
  let performDismiss: () -> Void

  @State private var imageWidth: CGFloat = 300
  @State private var saveComplete = false
  @State private var alertDetails: AlertDetails?

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @FocusState private var isContextFieldFocused: Bool

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  var body: some View {
    ScrollView {
      VStack {
        FoodItemLogPickerHeader()

        if let squareImage = image.croppedToSquare() {
          Image(uiImage: squareImage)
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(square: imageWidth)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }

        TextField(
          "",
          text: $contextText,
          prompt: Text("Add extra details about your meal."),
          axis: .vertical
        )
        .focused($isContextFieldFocused)
        .submitLabel(.done)
        .onSubmit {
          isContextFieldFocused = false
        }
        .onChange(of: contextText) { oldValue, newValue in
          if let newLineIndex = newValue.lastIndex(of: "\n") {
            contextText.remove(at: newLineIndex)
            isContextFieldFocused = false
          }
        }
        .font(.title2)
        .fontDesign(.rounded)
        .lineLimit(3...6)
        .bold()
        .multilineTextAlignment(.leading)
        .cardContainer()
      }
      .readViewSize { proxy in
        imageWidth = proxy.size.width
      }
      .padding()
    }
    .sensoryFeedback(.success, trigger: saveComplete)
    .alert(alertDetails: $alertDetails)
    .presentationCornerRadius(30)
    .presentationDetents([.fraction(0.85), .large])
    .presentationDragIndicator(.visible)
    .shelf {
      AsyncButton {
        try await handleSave()
      } label: {
        Text("Save")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
  }

  private func handleSave() async throws {
    // Crop and resize image
    guard let squareImage = image.croppedToSquare(),
          let imageData = BackendImageResizer.resize(squareImage) else {
      alertDetails = AlertDetails(title: "Error", message: "Unable to process image")
      return
    }

    // Save via NutritionTrackingViewModel
    let processingIdentifier = nutritionViewModel.logMagicScan(
      modelContext: modelContext,
      imageData: imageData,
      contextText: contextText,
      date: nutritionViewModel.date,
      meal: nutritionViewModel.suggestedMeal
    )

    // Upload to backend
    do {
      _ = try await NetworkRequester.shared.uploadMagicScan(
        imageData: imageData,
        contextText: contextText.isEmpty ? nil : contextText,
        processingIdentifier: AIFoodProcessingIdentifier(processingIdentifier)
      )
    } catch {
      // If upload fails, mark the item as failed
      try await nutritionViewModel.failMagicScan(
        modelContext: modelContext,
        processingIdentifier: AIFoodProcessingIdentifier(processingIdentifier),
        errorMessage: "Failed to upload image"
      )
    }

    // Trigger feedback and sound
    saveComplete.toggle()
    SoundPlayer.playLogHealthData()

    // Dismiss both sheet and camera
    performDismiss()
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
        performDismiss: { print("Dismiss all") }
      )
    }
  }
}
