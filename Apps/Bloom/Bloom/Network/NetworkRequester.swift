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

// MARK: - Authentication

extension NetworkRequester {

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

extension NetworkRequester {

  func foodAutocomplete(query: String) async throws -> [String] {
    let body = FoodAutocompleteRequest(query: query)
    let request = try await URLRequest.Food.autocomplete(body: body)

    let response = try await URLSession.shared.authenticatedBloomRequestWithResponse(
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
    let response = try await URLSession.shared.authenticatedBloomRequestWithResponse(
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
}

// MARK: - Chat

extension NetworkRequester {

  func openChatWebsocket(isV1: Bool) async -> WebSocketHandle {
    var request = await URLRequest.Chat.webSocket().settingBloomHeaders()

    if isV1 {
      request = request.settingAPIVersionHeader(version: "v1")
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
}

// MARK: - Goals

extension NetworkRequester {

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

// MARK: - Legacy

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
