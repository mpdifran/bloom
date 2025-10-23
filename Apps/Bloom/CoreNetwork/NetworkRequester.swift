//
//  NetworkRequester.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI
import BloomModel
import AppFoundations

public final class NetworkRequester: Sendable {
  public static let shared = NetworkRequester()
}

// MARK: - Authentication

public extension NetworkRequester {

  func authenticate(request: AuthenticationRequest) async throws -> AuthenticationResponse {
    let request = try await URLRequest.Auth.signIn(body: request)

    return try await URLSession.shared.bloomRequestWithResponse(
      request: request,
      responseType: AuthenticationResponse.self
    )
  }

  func identify(request: AuthIdentifyRequest) async throws -> AuthIdentifyResponse {
    let request = try await URLRequest.User.identify(body: request)

    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: AuthIdentifyResponse.self
    )
  }

  func register(deviceToken: String) async throws -> Void {
    let request = try await URLRequest.User.registerDeviceToken(body: RegisterUserPushNotificationTokenRequest(deviceToken: deviceToken))
    try await URLSession.shared.authenticatedBloomRequest(request: request)
  }

  func signOut() async throws {
    let request = await URLRequest.User.logout()
    try await URLSession.shared.authenticatedBloomRequest(request: request)
  }

  func deleteAccount() async throws {
    let request = await URLRequest.User.deleteAccount()
    try await URLSession.shared.authenticatedBloomRequest(request: request)
  }
}

// MARK: - Food

public extension NetworkRequester {

  func foodAutocomplete(query: String) async throws -> [String] {
    let body = FoodAutocompleteRequest(query: query)
    let request = try await URLRequest.Food.autocomplete(body: body)

    let response = try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: FoodAutocompleteResponse.self
    )
    return response.tokens
  }

  func foodSearch(name: String, brand: String?, preferredCountry: String) async throws -> [FoodSearchResponse.Section] {
    let body = FoodSearchRequest(
      name: name,
      brand: brand,
      country: preferredCountry
    )
    let request = try await URLRequest.Food.search(body: body)
    let response = try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: FoodSearchResponse.self
    )
    return response.sections
  }

  func foodSearch(
    upcCode: String,
    country: String
  ) async throws -> [FoodSearchResponse.Section] {
    let body = FoodSearchRequest(
      upcCode: upcCode,
      country: country
    )
    let request = try await URLRequest.Food.search(body: body)
    let response = try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: FoodSearchResponse.self
    )
    return response.sections
  }

  func uploadFood(
    barcode: String,
    nutritionImage: UIImage,
    packagingImage: UIImage,
    country: String
  ) async throws -> UploadNewFoodResponse {
    guard
      let nutritionData = nutritionImage.pngData(),
      let packagingData = packagingImage.pngData()
    else {
      throw NSError(description: "There was an issue uploading the images.")
    }

    let body = UploadNewFoodRequest(
      barcode: barcode,
      nutritionLabelImage: ImageFile(
        data: nutritionData,
        fileExtension: "png"
      ),
      packagingImage: ImageFile(
        data: packagingData,
        fileExtension: "png"
      ),
      country: country
    )

    let request = try await URLRequest.Food.uploadFood(body: body)
    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: UploadNewFoodResponse.self
    )
  }

  func foodAIEstimate(image: UIImage, foodDescription: String?) async throws -> EstimateFoodCaloriesResponse {
    guard let imageData = image.pngData() else {
      throw NSError(description: "There was an issue uploading the image.")
    }

    let body = EstimateFoodCaloriesRequest(
      foodImage: ImageFile(
        data: imageData,
        fileExtension: "png"
      ),
      foodDescription: foodDescription
    )

    let request = try await URLRequest.Food.estimateFood(body: body)
    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: EstimateFoodCaloriesResponse.self
    )
  }

  func foodAITextEstimate(foodDescription: String) async throws -> EstimateFoodCaloriesResponse {
    let body = EstimateFoodCaloriesRequest(foodDescription: foodDescription)

    let request = try await URLRequest.Food.estimateFood(body: body)
    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: EstimateFoodCaloriesResponse.self
    )
  }

  func submitFoodIssueReport(issue: FoodItemIssue) async throws {
    let body = SubmitFoodItemIssueRequest(foodItemIssue: issue)
    let request = try await URLRequest.Food.submitFoodItemIssue(body: body)
    try await URLSession.shared.authenticatedBloomRequest(request: request)
  }

  func markFoodAsInaccurate(foodID: FoodItemIdentifier) async throws {
    let body = MarkFoodInaccurateRequest(
      foodId: foodID
    )
    let request = try await URLRequest.Food.markAsInaccurate(body: body)
    try await URLSession.shared.authenticatedBloomRequest(request: request)
  }

  func trackFoodLog(foodIDs: [FoodItemIdentifier]) async throws {
    guard !foodIDs.isEmpty else { return }

    let body = TrackFoodLogRequest(
      foodIds: foodIDs
    )
    let request = try await URLRequest.Food.trackLog(body: body)
    try await URLSession.shared.authenticatedBloomRequest(request: request)
  }

  func getFoodItem(id: String) async throws -> FoodItem {
    let request = await URLRequest.Food.getById(foodId: id)
    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: FoodItem.self
    )
  }
}

// MARK: - Today Content

public extension NetworkRequester {

  func getTodayInsights(request: TodayReportRequest) async throws -> TodayReportResponse {
    let urlRequest = try await URLRequest.AI.getTodayView(body: request)
    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: urlRequest,
      responseType: TodayReportResponse.self
    )
  }
}

// MARK: - Biological Age

public extension NetworkRequester {

  func getBiologicalAge(request: BiologicalAgeRequest) async throws -> BiologicalAgeResponse {
    let urlRequest = try await URLRequest.BiologicalAge.calculate(body: request)
    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: urlRequest,
      responseType: BiologicalAgeResponse.self
    )
  }
}

// MARK: - Chat

public extension NetworkRequester {

  func openChatWebsocket(modelOverride: String? = nil) async -> WebSocketHandle {
    var request = await URLRequest.Chat.webSocket().settingBloomHeaders()

    if let modelOverride {
      request = request.settingOpenAIModelHeader(model: modelOverride)
    }

    let task = URLSession.shared.webSocketTask(with: request)
    return WebSocketHandle(task: task)
  }

  func submitToolCallResponse(body: SocketMessage.ToolCallsResponse) async throws {
    let request = try await URLRequest.Chat.submitToolCallResponse(body: body)
    try await URLSession.shared.authenticatedBloomRequest(request: request)
  }

  func uploadChatImages(images: [Data]) async throws -> ChatUploadFileResponse {
    let body = ChatUploadFileRequest(images: images)
    let request = try await URLRequest.Chat.uploadImage(body: body)
    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: ChatUploadFileResponse.self
    )
  }

  func deleteChatThread() async throws {
    let request = await URLRequest.Chat.deleteChatThread()
    try await URLSession.shared.authenticatedBloomRequest(request: request)
  }

  func submitChatMessageIssueReport(request: SubmitChatMessageIssueRequest) async throws {
    let urlRequest = try await URLRequest.Chat.reportIssue(body: request)
    try await URLSession.shared.authenticatedBloomRequest(request: urlRequest)
  }
}

// MARK: - Goals

public extension NetworkRequester {

  func suggestGoals(healthData: String, currentGoals: String) async throws -> SuggestGoalsResponse {
    let body = SuggestGoalsRequest(
      healthData: healthData,
      currentGoals: currentGoals,
      isConversation: false
    )
    let request = try await URLRequest.Goals.suggestGoals(body: body)
    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: request,
      responseType: SuggestGoalsResponse.self
    )
  }
}

// MARK: - Reports

public extension NetworkRequester {

  func getMorningHealthReport(request: MorningHealthReportRequest) async throws -> MorningHealthReportResponse {
    let urlRequest = try await URLRequest.Reports.getMorningHealthReport(body: request)
    return try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: urlRequest,
      responseType: MorningHealthReportResponse.self
    )
  }
}
