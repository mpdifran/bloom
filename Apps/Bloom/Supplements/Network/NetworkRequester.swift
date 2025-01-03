//
//  NetworkRequester.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI
import BloomModel

private extension String {
  static let usdaAPIKey = "d8qTh8MkWmXtiqUjVvO2dv7w64W9wDOTnAYY6pJa"

  static let bloomAPIBase = "https://bloom-api-5903aeb2ee43.herokuapp.com/"
}

final class NetworkRequester: Sendable {
  static let shared = NetworkRequester()
}

extension NetworkRequester {

  func authenticate(request: AuthenticationRequest) async throws -> AuthenticationResponse {
    let request = try URLRequest.Auth.signIn(request: request)
    let (data, _) = try await URLSession.shared.data(for: request)

    if let string = String(data: data, encoding: .utf8) {
      print(string)
    }

    return try JSONDecoder.bloomModel.decode(AuthenticationResponse.self, from: data)
  }
}

extension NetworkRequester {

  func foodAutocomplete(query: String) async throws -> [String] {
    let url = URL(string: .bloomAPIBase + "v1/food/autocomplete")!

    let request = FoodAutocompleteRequest(query: query)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(request)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    let response = try JSONDecoder.bloomModel.decode(FoodAutocompleteResponse.self, from: data)

    return response.tokens
  }


  func foodSearch(name: String, brand: String?, preferredCountry: FoodCountry) async throws -> [FoodSearchResponse.Section] {
    let url = URL(string: .bloomAPIBase + "v1/food/search")!

    let request = FoodSearchRequest(
      name: name,
      brand: brand,
      country: preferredCountry
    )

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(request)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    let response = try JSONDecoder.bloomModel.decode(FoodSearchResponse.self, from: data)

    return response.sections
  }

  func foodSearch(
    upcCode: String,
    country: FoodCountry
  ) async throws -> [FoodSearchResponse.Section] {
    let url = URL(string: .bloomAPIBase + "v1/food/search")!

    let request = FoodSearchRequest(
      upcCode: upcCode,
      country: country
    )

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(request)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    let response = try JSONDecoder.bloomModel.decode(FoodSearchResponse.self, from: data)

    return response.sections
  }

  func uploadFood(
    barcode: String,
    nutritionImage: UIImage,
    packagingImage: UIImage,
    country: FoodCountry
  ) async throws -> UploadNewFoodResponse {
    let url = URL(string: .bloomAPIBase + "v1/food/upload")!

    guard
      let nutritionData = nutritionImage.pngData(),
      let packagingData = packagingImage.pngData()
    else {
      throw NSError(description: "There was an issue uploading the images.")
    }

    let request = UploadNewFoodRequest(
      barcode: barcode,
      nutritionLabelImage: .init(
        data: nutritionData,
        fileExtension: "png"
      ),
      packagingImage: .init(
        data: packagingData,
        fileExtension: "png"
      ),
      country: country
    )

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(request)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    let response = try JSONDecoder.bloomModel.decode(UploadNewFoodResponse.self, from: data)

    return response
  }

  func foodAIEstimate(image: UIImage) async throws -> EstimateFoodCaloriesResponse {
    let url = URL(string: .bloomAPIBase + "v1/food/estimate")!

    guard let imageData = image.pngData() else {
      throw NSError(description: "There was an issue uploading the image.")
    }

    let request = EstimateFoodCaloriesRequest(
      foodImage: .init(
        data: imageData,
        fileExtension: "png"
      )
    )

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(request)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    let response = try JSONDecoder.bloomModel.decode(EstimateFoodCaloriesResponse.self, from: data)

    return response
  }

  func markFoodAsInaccurate(foodID: FoodItemIdentifier) async throws {
    let url = URL(string: .bloomAPIBase + "v1/food/mark-as-inaccurate")!

    let request = MarkFoodInaccurateRequest(
      foodId: foodID
    )

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(request)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let _ = try await URLSession.shared.data(for: urlRequest)
  }
}

extension NetworkRequester {

  func sendQuery(
    userInfo: UserInfoModel?,
    currentGoals: [String],
    currentSupplements: [String],
    chatHistory: [ChatMessageHistory],
    learnedUserFacts: [String]
  ) async throws -> AskResponseModel {
    let request = AskRequestModel(
      userInfo: userInfo,
      currentSupplements: currentSupplements,
      currentGoals: currentGoals,
      chatHistory: chatHistory,
      learnedUserFacts: learnedUserFacts
    )

    let requestData = try JSONEncoder.main.encode(request)

    let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/ask")!
    var urlRequest = URLRequest(url: url)
    urlRequest.httpBody = requestData
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.main.decode(AskResponseModel.self, from: data)
  }

  func sendProactiveTip(
    request: ProactiveTipRequestModel
  ) async throws -> ProactiveTipResponseModel {

    let requestData = try JSONEncoder.main.encode(request)

    let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/proactive-tip")!
    var urlRequest = URLRequest(url: url)
    urlRequest.httpBody = requestData
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.main.decode(ProactiveTipResponseModel.self, from: data)
  }

  func fetchGoals() async throws -> [String] {
    let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/goals?max=100")!
    let (data, _) = try await URLSession.shared.data(from: url)

    return try JSONDecoder.main.decode([String].self, from: data)
  }

  func fetchSupplements() async throws -> [String] {
    let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/supplements?max=100")!
    let (data, _) = try await URLSession.shared.data(from: url)

    return try JSONDecoder.main.decode([String].self, from: data)
  }

  func parseOnboardingInfo(request: OnboardingInfoRequest) async throws -> OnboardingInfoResponse {
    let url = URL(string: "https://shep-test-7d27e987b8ef.herokuapp.com/onboarding-info")!

    let requestData = try JSONEncoder.main.encode(request)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpBody = requestData
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.main.decode(OnboardingInfoResponse.self, from: data)
  }
}
