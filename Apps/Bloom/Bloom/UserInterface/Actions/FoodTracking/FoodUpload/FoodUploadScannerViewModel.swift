//
//  FoodUploadScannerViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-18.
//

import SwiftUI
import AppUI
import BloomModel
import TelemetryDeck

extension FoodUploadScannerView {
  @Observable @MainActor
  final class ViewModel {
    var barcode: String?
    var nutritionLabelImage: UIImage?
    var packagingImage: UIImage?
    var country: FoodCountry = .usa

    init(barcode: String?) {
      self.barcode = barcode
    }

    var isLoading = false
    var alertDetails: AlertDetails?
  }
}

extension FoodUploadScannerView.ViewModel {

  func onAppear() {
    LocationManagerViewModel.shared.requestLocation()
    if let country = LocationManagerViewModel.shared.country {
      self.country = country
    }
  }

  var canUpload: Bool {
    barcode != nil && nutritionLabelImage != nil && packagingImage != nil
  }

  func upload() async throws -> FoodItem {
    guard
      let barcode,
      let nutritionLabelImage = nutritionLabelImage?.resized(toWidth: 1000),
      let packagingImage = packagingImage?.resized(toWidth: 1000)
    else {
      throw NSError(description: "Cannot upload with missing data")
    }

    isLoading = true
    let response = try await NetworkRequester.shared.uploadFood(
      barcode: barcode,
      nutritionImage: nutritionLabelImage,
      packagingImage: packagingImage,
      country: country
    )
    isLoading = false

    switch response.result {
    case .foodLogged:
      self.alertDetails = AlertDetails(title: "Food Uploaded", message: "Food was successfully uploaded.")
      TelemetryDeck.signal("Uploaded Food", parameters: ["foodUploadResult" : "Logged"])
    case .unclearNutritionLabel:
      self.alertDetails = AlertDetails(title: "Unclear Nutrition Label", message: "The nutrition label for this food is unclear. Please take another picture.")
      self.nutritionLabelImage = nil
      TelemetryDeck.signal("Uploaded Food", parameters: ["foodUploadResult" : "Unclear Nutrition Label"])
    case .unclearPackaging:
      self.alertDetails = AlertDetails(title: "Unclear Packaging", message: "The packaging for this food is unclear. Please take another picture.")
      self.packagingImage = nil
      TelemetryDeck.signal("Uploaded Food", parameters: ["foodUploadResult" : "Unclear Packaging"])
    }

    guard let foodItem = response.foodItem else {
      throw NSError(description: "There was a problem uploading the food.")
    }

    return foodItem
  }
}
