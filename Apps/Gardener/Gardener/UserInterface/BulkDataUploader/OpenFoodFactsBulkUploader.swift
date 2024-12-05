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
  @State private var fileLineNumber = 0
  @State private var totalLineNumbers = 1
  @State private var alertDetails: AlertDetails?
  @State private var error: Error?

  var body: some View {
    Form {
      fileSection
      uploadSection
    }
    .formStyle(.grouped)
    .pickFile(showPicker: $showDirectoryPicker) { fileURL in
      self.fileURL = fileURL
    }
    .animation(.default, value: fileLineNumber)
    .animation(.default, value: totalLineNumbers)
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
    }
  }

  var uploadSection: some View {
    Section("Upload") {
      Text("\(fileLineNumber) food items uploaded")
        .font(.title2)
        .bold()

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

private extension OpenFoodFactsBulkUploader {

  func performUpload() async throws {
    guard let fileURL else { return }

    let decoder = JSONDecoder()

    try await FileHandle.readFileLines(from: fileURL) { line in
      guard let data = line.data(using: .utf8) else { return true }

      do {
        let foodItem = try decoder.decode(OpenFoodFactsFoodItem.self, from: data)
        print(foodItem)
      } catch {
        print(error)
        throw error
      }



      await MainActor.run {
        fileLineNumber += 1
      }

      return false
    }

    await MainActor.run {
      alertDetails = AlertDetails(title: "Upload Complete", message: "Uploaded \(totalLineNumbers) food items.")
    }
  }
}

#Preview {
  OpenFoodFactsBulkUploader()
}
