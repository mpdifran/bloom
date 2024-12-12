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
  @State private var endAtLineNumber = 0
  @State private var bulkRequestItemCount = 500
  @State private var isUploading = false
  @State private var alertDetails: AlertDetails?
  @State private var error: Error?

  @AppStorage("lastParsedLine") private var lastParsedLine = 0

  let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()

  var body: some View {
    Form {
      fileSection
      uploadSection
    }
    .formStyle(.grouped)
    .pickFile(showPicker: $showDirectoryPicker) { fileURL in
      self.fileURL = fileURL
    }
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
      TextField("Start At Line", value: $startAtLineNumber, formatter: NumberFormatter.noDecimalPlaces)
        .textFieldStyle(.roundedBorder)

      TextField("End At Line", value: $endAtLineNumber, formatter: NumberFormatter.noDecimalPlaces)
        .textFieldStyle(.roundedBorder)

      TextField("Bulk Request Size", value: $bulkRequestItemCount, formatter: NumberFormatter.noDecimalPlaces)
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

    uploadedItemCount = 0
    insertedItemCount = 0
    
    isUploading = true

    currentLine = 0
    var items = [AdminOpenFoodFactsBulkUploadItem]()

    try await FileHandle.readFileLines(from: fileURL) { line in
      guard isUploading else { return false }

      defer {
        currentLine += 1
        lastParsedLine = currentLine
      }

      if endAtLineNumber > 0 {
        if currentLine >= endAtLineNumber { return false }
      }

      guard
        currentLine >= startAtLineNumber,
        let data = line.data(using: .utf8)
      else { return true }

      do {
        let foodItem = try decoder.decode(OpenFoodFactsFoodItem.self, from: data)

        guard foodItem.isValid else { return true }

//        let string = String(data: data, encoding: .utf8) ?? ""

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
          servingName: foodItem.formattedQuantityName(),
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
          cholesterol: foodItem.nutriments?.cholesterolServing?.mg,
          sodium: foodItem.nutriments?.sodiumServing?.mg,
          calcium: foodItem.nutriments?.calciumServing?.mg,
          iron: foodItem.nutriments?.ironServing?.mg,
          potassium: foodItem.nutriments?.potassiumServing?.mg,
          magnesium: foodItem.nutriments?.magnesiumServing?.mg,
          zinc: foodItem.nutriments?.zincServing?.mg,
          vitaminA: foodItem.nutriments?.vitaminAServing?.mg,
          vitaminB6: foodItem.nutriments?.vitaminB6Serving?.mg,
          vitaminB12: foodItem.nutriments?.vitaminB12Serving?.mg,
          vitaminC: foodItem.nutriments?.vitaminCServing?.mg,
          vitaminD: foodItem.nutriments?.vitaminDServing?.mg,
          vitaminE: foodItem.nutriments?.vitaminEServing?.mg
        )

        items.append(item)
      } catch {
        print(error)
      }

      if items.count >= bulkRequestItemCount {
        let itemsCopy = items
        Task {
          await upload(items: itemsCopy)
        }
        items.removeAll(keepingCapacity: true)
      }

      return true
    }

    if items.isNotEmpty {
      await upload(items: items)
    }

    await MainActor.run {
      let amount = NumberFormatter.oneDecimalPlaces.string(from: NSNumber(value: insertedItemCount)) ?? ""
      if isUploading {
        alertDetails = AlertDetails(title: "Upload Complete", message: "Inserted \(amount) food items into the DB.")
      } else {
        alertDetails = AlertDetails(title: "Cancelled Upload", message: "Inserted \(amount) food items into the DB.")
      }

      isUploading = false
    }
  }

  nonisolated
  func iterativelyReadLine(lineReader: FileLineReader, items: inout [AdminOpenFoodFactsBulkUploadItem]) async {
    guard let line = lineReader.nextLine else { return }

    await MainActor.run {
      currentLine += 1
      lastParsedLine = currentLine
    }

    let item = await readLine(line: line)

    if let item {
      items.append(item)
    }

    let requestItemCount = await bulkRequestItemCount

    if items.count >= requestItemCount {
      let itemsCopy = items
      Task {
        await upload(items: itemsCopy)
      }
      items.removeAll(keepingCapacity: true)
    }

    await iterativelyReadLine(lineReader: lineReader, items: &items)
  }

  nonisolated
  func readLine(line: String) async -> AdminOpenFoodFactsBulkUploadItem? {
    guard await isUploading else { return nil }

    guard
      let data = line.data(using: .utf8)
    else { return nil }

    do {
      let foodItem = try decoder.decode(OpenFoodFactsFoodItem.self, from: data)

      guard foodItem.isValid else { return nil }

//        let string = String(data: data, encoding: .utf8) ?? ""

      guard
        let code = foodItem.id ?? foodItem.code,
        let servingQuantity = foodItem.servingQuantity,
        let servingUnit = foodItem.servingQuantityUnit,
        let energy = foodItem.nutriments?.energyServing
      else {
        return nil
      }

      let item = AdminOpenFoodFactsBulkUploadItem(
        productName: foodItem.productName,
        brand: foodItem.brands,
        barcode: code,
        countries: foodItem.sanitizedCountries,
        ingredients: foodItem.ingredientsTextEn,
        servingName: foodItem.formattedQuantityName(),
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
        cholesterol: foodItem.nutriments?.cholesterolServing?.mg,
        sodium: foodItem.nutriments?.sodiumServing?.mg,
        calcium: foodItem.nutriments?.calciumServing?.mg,
        iron: foodItem.nutriments?.ironServing?.mg,
        potassium: foodItem.nutriments?.potassiumServing?.mg,
        magnesium: foodItem.nutriments?.magnesiumServing?.mg,
        zinc: foodItem.nutriments?.zincServing?.mg,
        vitaminA: foodItem.nutriments?.vitaminAServing?.mg,
        vitaminB6: foodItem.nutriments?.vitaminB6Serving?.mg,
        vitaminB12: foodItem.nutriments?.vitaminB12Serving?.mg,
        vitaminC: foodItem.nutriments?.vitaminCServing?.mg,
        vitaminD: foodItem.nutriments?.vitaminDServing?.mg,
        vitaminE: foodItem.nutriments?.vitaminEServing?.mg
      )

      return item
    } catch {
      print(error)
    }
    return nil
  }

  func upload(items: [AdminOpenFoodFactsBulkUploadItem]) async {
    uploadedItemCount += items.count
    let request = AdminOpenFoodFactsBulkUploadRequest(items: items)
    do {
      let response = try await NetworkStack.shared.bulkUploadOpenFoodFacts(request: request)
      insertedItemCount += response.insertedCount
    } catch {
      print(error)
    }
  }
}

#Preview {
  OpenFoodFactsBulkUploader()
}
