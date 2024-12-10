//
//  OpenFoodFactsBulkUploader.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-04.
//

import SwiftUI
import AppUI
import BloomModel

struct OpenFoodFactsBulkUploader: View {

  @State private var fileURL: URL?
  @State private var showDirectoryPicker = false
  @State private var uploadedItemCount = 0
  @State private var insertedItemCount = 0
  @State private var currentLine = 0
  @State private var startAtLineNumber = 0
  @State private var isUploading = false
  @State private var alertDetails: AlertDetails?
  @State private var error: Error?

  @AppStorage("lastParsedLine") private var lastParsedLine = 0

  var body: some View {
    Form {
      fileSection
      uploadSection
    }
    .formStyle(.grouped)
    .pickFile(showPicker: $showDirectoryPicker) { fileURL in
      self.fileURL = fileURL
    }
    .animation(.default, value: uploadedItemCount)
    .animation(.default, value: currentLine)
    .alert(alertDetails: $alertDetails)
    .alert(error: $error)
  }
}

private extension OpenFoodFactsBulkUploader {

  var fileSection: some View {
    Section("File") {
      LabeledContent("File") {
        if let fileURL {
          Text(fileURL.lastPathComponent)
        } else {
          Text("No File Selected")
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        showDirectoryPicker.toggle()
      }

      LabeledContent("Last Uploaded Line") {
        Text("\(lastParsedLine)")
      }
    }
  }

  var uploadSection: some View {
    Section("Upload") {
      TextField("Line Offset", value: $startAtLineNumber, formatter: NumberFormatter.noDecimalPlaces)
        .textFieldStyle(.roundedBorder)

      LabeledContent("Current Line") {
        Text("\(currentLine)")
          .contentTransition(.numericText(value: Double(currentLine)))
      }

      LabeledContent("Uploaded") {
        Text("\(uploadedItemCount) Food Items")
      }
      LabeledContent("Inserted Into DB") {
        Text("\(insertedItemCount) Food Items")
      }

      if isUploading {
        ProminentButton("Cancel") {
            isUploading = false
        }
      } else {
        ProminentButton("Upload") {
          Task {
            do {
              try await performUpload()
            } catch {
              self.error = error
            }
          }
        }
        .disabled(fileURL == nil)
      }
    }
  }
}

private extension OpenFoodFactsBulkUploader {

  func performUpload() async throws {
    guard let fileURL else { return }

    isUploading = true

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    currentLine = 0
    var items = [AdminOpenFoodFactsBulkUploadItem]()

    try await FileHandle.readFileLines(from: fileURL) { line in
      guard isUploading else { return false }

      defer {
        currentLine += 1
        lastParsedLine = currentLine
      }

      guard
        currentLine >= startAtLineNumber,
        let data = line.data(using: .utf8)
      else { return true }

      do {
        let foodItem = try decoder.decode(OpenFoodFactsFoodItem.self, from: data)

        guard foodItem.isValid else { return true }

//        let string = String(data: data, encoding: .utf8) ?? ""

        _ = foodItem.hasValidNutrimentUnit

        guard
          let code = foodItem.id ?? foodItem.code,
          let servingQuantity = foodItem.servingQuantity,
          let servingUnit = foodItem.servingQuantityUnit,
          let energy = foodItem.nutriments?.energyServing
        else {
          return true
        }

        let item = AdminOpenFoodFactsBulkUploadItem(
          productName: foodItem.productName,
          brand: foodItem.brands,
          barcode: code,
          countries: foodItem.sanitizedCountries,
          ingredients: foodItem.ingredientsTextEn,
          servingQuantity: servingQuantity,
          servingUnit: servingUnit,
          packagingImageURL: foodItem.frontImageURL,
          nutrientsImageURL: foodItem.nutritionImageURL,
          energy: energy,
          protein: foodItem.nutriments?.proteinsServing,
          carbohydrates: foodItem.nutriments?.carbohydratesServing,
          fat: foodItem.nutriments?.fatServing,
          saturatedFat: foodItem.nutriments?.saturatedFatServing,
          transFat: foodItem.nutriments?.transFatServing,
          polyunsaturatedFat: foodItem.nutriments?.polyunsaturatedFatServing,
          monounsaturatedFat: foodItem.nutriments?.monounsaturatedFatServing,
          fiber: foodItem.nutriments?.fiberServing,
          sugar: foodItem.nutriments?.sugarsServing,
          cholesterol: try foodItem.nutriments?.resolvedMilligramBasedUnit(serving: \.cholesterolServing, unit: \.cholesterolUnit),
          sodium: try foodItem.nutriments?.resolvedMilligramBasedUnit(serving: \.sodiumServing, unit: \.sodiumUnit),
          calcium: try foodItem.nutriments?.resolvedMilligramBasedUnit(serving: \.calciumServing, unit: \.calciumUnit),
          iron: try foodItem.nutriments?.resolvedMilligramBasedUnit(serving: \.ironServing, unit: \.ironUnit),
          potassium: try foodItem.nutriments?.resolvedMilligramBasedUnit(serving: \.potassiumServing, unit: \.potassiumUnit),
          magnesium: try foodItem.nutriments?.resolvedMilligramBasedUnit(serving: \.magnesiumServing, unit: \.magnesiumUnit),
          zinc: try foodItem.nutriments?.resolvedMilligramBasedUnit(serving: \.zincServing, unit: \.zincUnit),
          vitaminA: try foodItem.nutriments?.resolvedVitaminAServing(),
          vitaminB6: foodItem.nutriments?.vitaminB6Serving,
          vitaminB12: try foodItem.nutriments?.resolvedVitaminB12Serving(),
          vitaminC: try foodItem.nutriments?.resolvedVitaminCServing(),
          vitaminD: try foodItem.nutriments?.resolvedVitaminDServing(),
          vitaminE: try foodItem.nutriments?.resolvedVitaminEServing()
        )

        items.append(item)
      } catch {
        print(error)
      }

      if items.count >= 100 {
        let itemsCopy = items
        items.removeAll(keepingCapacity: true)
        Task {
          try await upload(items: items)
        }
      }

      return true
    }

    if items.isNotEmpty {
      try await upload(items: items)
    }

    await MainActor.run {
      let amount = NumberFormatter.oneDecimalPlaces.string(from: NSNumber(value: uploadedItemCount)) ?? ""
      if isUploading {
        alertDetails = AlertDetails(title: "Upload Complete", message: "Uploaded \(amount) food items.")
      } else {
        alertDetails = AlertDetails(title: "Cancelled Upload", message: "Uploaded \(amount) food items.")
      }

      isUploading = false
    }
  }

  func upload(items: [AdminOpenFoodFactsBulkUploadItem]) async throws {
    let request = AdminOpenFoodFactsBulkUploadRequest(items: items)
    let response = try await NetworkStack.shared.bulkUploadOpenFoodFacts(request: request)
    uploadedItemCount += items.count
    insertedItemCount += response.insertedCount
  }
}

#Preview {
  OpenFoodFactsBulkUploader()
}
