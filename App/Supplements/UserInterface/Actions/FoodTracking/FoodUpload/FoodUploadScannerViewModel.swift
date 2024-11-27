//
//  FoodUploadScannerViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-18.
//

import SwiftUI
import AppUI
import BloomModel

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

        var alertDetails: AlertDetails?
    }
}

extension FoodUploadScannerView.ViewModel {

    func onAppear() {
        LocationManagerViewModel.shared.requestLocation()
    }

    var canUpload: Bool {
        barcode != nil && nutritionLabelImage != nil && packagingImage != nil
    }

    func upload() async throws {
        guard
            let barcode,
            let nutritionLabelImage = nutritionLabelImage?.resized(toWidth: 700),
            let packagingImage = packagingImage?.resized(toWidth: 700)
        else {
            throw NSError(description: "Cannot upload with missing data")
        }

        let response = try await NetworkRequester.shared.uploadFood(
            barcode: barcode,
            nutritionImage: nutritionLabelImage,
            packagingImage: packagingImage,
            country: country
        )

        switch response.result {
        case .foodLogged:
            self.alertDetails = AlertDetails(title: "Food Uploaded", message: "Food was successfully uploaded.")
        case .unclearNutritionLabel:
            self.alertDetails = AlertDetails(title: "Unclear Nutrition Label", message: "The nutrition label for this food is unclear. Please take another picture.")
            self.nutritionLabelImage = nil
        case .unclearPackaging:
            self.alertDetails = AlertDetails(title: "Unclear Packaging", message: "The packaging for this food is unclear. Please take another picture.")
            self.packagingImage = nil
        }
    }
}
