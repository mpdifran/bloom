//
//  UploadNewFoodRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation

public struct UploadNewFoodRequest: Codable {
    public let barcode: String
    public let nutritionLabelImage: ImageFile
    public let packagingImage: ImageFile
    public let country: String

    public init(
        barcode: String,
        nutritionLabelImage: ImageFile,
        packagingImage: ImageFile,
        country: String
    ) {
        self.barcode = barcode
        self.nutritionLabelImage = nutritionLabelImage
        self.packagingImage = packagingImage
        self.country = country
    }
}
