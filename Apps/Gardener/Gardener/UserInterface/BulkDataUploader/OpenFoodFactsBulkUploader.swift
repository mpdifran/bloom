//
//  OpenFoodFactsBulkUploader.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-04.
//

import SwiftUI
import AppUI

struct OpenFoodFactsBulkUploader: View {

  @State private var fileURL: URL?
  @State private var showDirectoryPicker = false
  @State private var uploadedItemCount = 0
  @State private var currentLine = 0
  @State private var startAtLineNumber = 0
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

      LabeledContent("Uploaded") {
        Text("\(uploadedItemCount) Food Items")
      }
    }
  }
}

private extension OpenFoodFactsBulkUploader {

  func performUpload() async throws {
    guard let fileURL else { return }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    currentLine = 0
    try await FileHandle.readFileLines(from: fileURL) { line in
      defer {
        currentLine += 1
        lastParsedLine = currentLine
      }
      guard currentLine >= startAtLineNumber else { return true }

      guard let data = line.data(using: .utf8) else { return true }

      do {
        let foodItem = try decoder.decode(OpenFoodFactsFoodItem.self, from: data)
        if foodItem.selectedImages != nil {
          print(foodItem)
          uploadedItemCount += 1
          return false
        }
      } catch {
        print(error)
//        throw error
      }

      return true
    }

    await MainActor.run {
      alertDetails = AlertDetails(title: "Upload Complete", message: "Uploaded \(uploadedItemCount) food items.")
    }
  }
}

#Preview {
  OpenFoodFactsBulkUploader()
}
