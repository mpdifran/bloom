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

        let validCountries: Set<String> = ["en:canada", "en:Canada", "en:united-states"]
        guard foodItem.countriesTags.asSet().intersection(validCountries).isNotEmpty else { return true }
        guard let code = foodItem.id, let code = foodItem.code else { return true }

        let sanitizedCountries = foodItem.countriesTags.map({ $0.replacingOccurrences(of: "en:", with: "") })

        let item = AdminOpenFoodFactsBulkUploadItem(
          barcode: code,
          countries: sanitizedCountries,
          ingredients: foodItem.ingredientsTextEn
        )

        items.append(item)
      } catch {
        print(error)
      }

      if items.count > 99 {
        try await upload(items: items)
        items.removeAll(keepingCapacity: true)
      }

      return true
    }

    if items.isNotEmpty {
      try await upload(items: items)
    }

    await MainActor.run {
      if isUploading {
        alertDetails = AlertDetails(title: "Upload Complete", message: "Uploaded \(uploadedItemCount) food items.")
      } else {
        alertDetails = AlertDetails(title: "Cancelled Upload", message: "Uploaded \(uploadedItemCount) food items.")
      }
    }
  }

  func upload(items: [AdminOpenFoodFactsBulkUploadItem]) async throws {
    // Make request

    uploadedItemCount += items.count
  }
}

#Preview {
  OpenFoodFactsBulkUploader()
}
