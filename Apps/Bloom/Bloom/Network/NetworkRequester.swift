//
//  NetworkRequester.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI
import BloomModel

final class NetworkRequester: Sendable {
  static let shared = NetworkRequester()
}

extension NetworkRequester {

  func authenticate(request: AuthenticationRequest) async throws -> AuthenticationResponse {
    let request = try await URLRequest.Auth.signIn(body: request)

    return try await URLSession.shared.bloomResponse(
      request: request,
      responseType: AuthenticationResponse.self
    )
  }

  func signOut() async throws {
    let request = await URLRequest.User.logout()
    try await URLSession.shared.authenticatedBloomRequest(request: request)
  }
}

extension NetworkRequester {

  func foodAutocomplete(query: String) async throws -> [String] {
    let body = FoodAutocompleteRequest(query: query)
    let request = try await URLRequest.Food.autocomplete(body: body)

    let response = try await URLSession.shared.authenticatedBloomResponse(
      request: request,
      responseType: FoodAutocompleteResponse.self
    )
    return response.tokens
  }

  func foodSearch(name: String, brand: String?, preferredCountry: FoodCountry) async throws -> [FoodSearchResponse.Section] {
    let body = FoodSearchRequest(
      name: name,
      brand: brand,
      country: preferredCountry
    )
    let request = try await URLRequest.Food.search(body: body)
    let response = try await URLSession.shared.authenticatedBloomResponse(
      request: request,
      responseType: FoodSearchResponse.self
    )
    return response.sections
  }

  func foodSearch(
    upcCode: String,
    country: FoodCountry
  ) async throws -> [FoodSearchResponse.Section] {
    let body = FoodSearchRequest(
      upcCode: upcCode,
      country: country
    )
    let request = try await URLRequest.Food.search(body: body)
    let response = try await URLSession.shared.authenticatedBloomResponse(
      request: request,
      responseType: FoodSearchResponse.self
    )
    return response.sections
  }

  func uploadFood(
    barcode: String,
    nutritionImage: UIImage,
    packagingImage: UIImage,
    country: FoodCountry
  ) async throws -> UploadNewFoodResponse {
    guard
      let nutritionData = nutritionImage.pngData(),
      let packagingData = packagingImage.pngData()
    else {
      throw NSError(description: "There was an issue uploading the images.")
    }

    let body = UploadNewFoodRequest(
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

    let request = try await URLRequest.Food.uploadFood(body: body)
    return try await URLSession.shared.authenticatedBloomResponse(
      request: request,
      responseType: UploadNewFoodResponse.self
    )
  }

  func foodAIEstimate(image: UIImage) async throws -> EstimateFoodCaloriesResponse {
    guard let imageData = image.pngData() else {
      throw NSError(description: "There was an issue uploading the image.")
    }

    let body = EstimateFoodCaloriesRequest(
      foodImage: .init(
        data: imageData,
        fileExtension: "png"
      )
    )

    let request = try await URLRequest.Food.estimateFood(body: body)
    return try await URLSession.shared.authenticatedBloomResponse(
      request: request,
      responseType: EstimateFoodCaloriesResponse.self
    )
  }

  func markFoodAsInaccurate(foodID: FoodItemIdentifier) async throws {
    let body = MarkFoodInaccurateRequest(
      foodId: foodID
    )
    let request = try await URLRequest.Food.markAsInaccurate(body: body)
    try await URLSession.shared.authenticatedBloomRequest(request: request)
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
