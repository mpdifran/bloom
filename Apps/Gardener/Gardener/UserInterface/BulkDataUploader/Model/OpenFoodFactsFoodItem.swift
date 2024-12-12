//
//  OpenFoodFactsFoodItem.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-04.
//

import Foundation

private extension String {
  static let imageBaseS3URL = "https://openfoodfacts-images.s3.eu-west-3.amazonaws.com/data"
}

struct OpenFoodFactsFoodItem: Codable {
  let id: String?
  let productName: String?
  let brands: String?
  let code: String?
  let countriesTags: [String]
  let ingredientsTextEn: String?
  let servingSize: String?
  let servingQuantity: Double?
  let servingQuantityUnit: String?
  let nutriments: Nutriments?
  let images: Images?

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(String.self, forKey: .id)
    self.productName = try container.decodeIfPresent(String.self, forKey: .productName)
    self.brands = try container.decodeIfPresent(String.self, forKey: .brands)
    self.code = try container.decodeIfPresent(String.self, forKey: .code)
    self.countriesTags = try container.decode([String].self, forKey: .countriesTags)
    self.ingredientsTextEn = try container.decodeIfPresent(String.self, forKey: .ingredientsTextEn)
    self.servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)

    if let doubleQuantity = try? container.decodeIfPresent(Double.self, forKey: .servingQuantity) {
      self.servingQuantity = doubleQuantity
    } else if let stringQuantity = try? container.decodeIfPresent(String.self, forKey: .servingQuantity) {
      self.servingQuantity = Double(stringQuantity)
    } else {
      self.servingQuantity = nil
    }
    self.servingQuantityUnit = try container.decodeIfPresent(String.self, forKey: .servingQuantityUnit)
    self.nutriments = try container.decodeIfPresent(OpenFoodFactsFoodItem.Nutriments.self, forKey: .nutriments)
    self.images = try container.decodeIfPresent(OpenFoodFactsFoodItem.Images.self, forKey: .images)
  }
}

extension OpenFoodFactsFoodItem {
  var barcodeSegments: [String]? {
    guard var barcode = id ?? code else { return nil }

    if barcode.count == 8 {
      return [barcode]
    }

    while barcode.count < 13 {
      barcode = "0" + barcode
    }

    let group1 = String(barcode.prefix(3))
    let group2 = String(barcode.dropFirst(3).prefix(3))
    let group3 = String(barcode.dropFirst(6).prefix(3))
    let group4 = String(barcode.dropFirst(9))

    return [group1, group2, group3, group4]
  }

  var frontImageURL: URL? {
    guard
      var url = URL(string: .imageBaseS3URL),
      let barcodeSegments = barcodeSegments
    else { return nil }

    for segment in barcodeSegments {
      url = url.appending(path: segment)
    }

    if let id = images?.front?.imgid {
      url = url.appending(path: "\(id).400.jpg")
    } else if let id = images?.frontEn?.imgid {
      url = url.appending(path: "\(id).400.jpg")
    } else {
      return nil
    }

    return url
  }

  var nutritionImageURL: URL? {
    guard
      var url = URL(string: .imageBaseS3URL),
      let barcodeSegments = barcodeSegments
    else { return nil }

    for segment in barcodeSegments {
      url = url.appending(path: segment)
    }

    if let id = images?.nutrition?.imgid {
      url = url.appending(path: "\(id).400.jpg")
    } else if let id = images?.nutritionEn?.imgid {
      url = url.appending(path: "\(id).400.jpg")
    } else {
      return nil
    }

    return url
  }
}

extension OpenFoodFactsFoodItem {
  struct Images: Codable {
    let front: ImageDetails?
    let frontEn: ImageDetails?
    let nutrition: ImageDetails?
    let nutritionEn: ImageDetails?
  }

  struct ImageDetails: Codable {
    let imgid: String

    init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<OpenFoodFactsFoodItem.ImageDetails.CodingKeys> = try decoder.container(keyedBy: OpenFoodFactsFoodItem.ImageDetails.CodingKeys.self)
      if let id = try? container.decode(String.self, forKey: OpenFoodFactsFoodItem.ImageDetails.CodingKeys.imgid) {
        self.imgid = id
      } else {
        let id = try container.decode(Int.self, forKey: OpenFoodFactsFoodItem.ImageDetails.CodingKeys.imgid)
        self.imgid = String(id)
      }
    }
  }
}

extension OpenFoodFactsFoodItem {
  struct Nutriments: Codable {
    let energyServing: Double?
    let proteinsServing: Double?
    let carbohydratesServing: Double?
    let fatServing: Double?
    let saturatedFatServing: Double?
    let transFatServing: Double?
    let polyunsaturatedFatServing: Double?
    let monounsaturatedFatServing: Double?
    let fiberServing: Double?
    let sugarsServing: Double?
    let cholesterolServing: Double?
    let sodiumServing: Double?
    let calciumServing: Double?
    let ironServing: Double?
    let potassiumServing: Double?
    let magnesiumServing: Double?
    let zincServing: Double?
    let vitaminAServing: Double?
    let vitaminB6Serving: Double?
    let vitaminB12Serving: Double?
    let vitaminCServing: Double?
    let vitaminDServing: Double?
    let vitaminEServing: Double?

    enum CodingKeys: String, CodingKey {
      case energyServing = "energy-kcalServing"
      case proteinsServing
      case carbohydratesServing
      case fatServing
      case saturatedFatServing = "saturated-fatServing"
      case transFatServing = "trans-fatServing"
      case polyunsaturatedFatServing = "polyunsaturated-fatServing"
      case monounsaturatedFatServing = "monounsaturated-fatServing"
      case fiberServing
      case sugarsServing
      case cholesterolServing
      case sodiumServing
      case calciumServing
      case ironServing
      case potassiumServing
      case magnesiumServing
      case zincServing
      case vitaminAServing = "vitamin-aServing"
      case vitaminB6Serving = "vitamin-bSserving"
      case vitaminB12Serving = "vitamin-bS_serving"
      case vitaminCServing = "vitamin-cServing"
      case vitaminDServing = "vitamin-dServing"
      case vitaminEServing = "vitamin-eServing"
    }
  }
}

extension OpenFoodFactsFoodItem {

  var isValid: Bool {
    let validCountries: Set<String> = ["en:canada", "en:Canada", "en:united-states"]

    guard countriesTags.asSet().intersection(validCountries).isNotEmpty else {
      return false
    }

    return (id ?? code) != nil &&
    servingQuantity != nil &&
    servingQuantityUnit != nil &&
    nutriments?.energyServing != nil
  }

  var sanitizedCountries: [String] {
    countriesTags.map({ $0.replacingOccurrences(of: "en:", with: "").lowercased() })
  }

  func formattedQuantityName() -> String {
    guard let servingSize else { return "1 serving" }

    let pattern = "\\s*\\(.*?\\)"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: servingSize.utf16.count)
    let result = regex.stringByReplacingMatches(in: servingSize, options: [], range: range, withTemplate: "")

    return result.lowercased()
  }
}
