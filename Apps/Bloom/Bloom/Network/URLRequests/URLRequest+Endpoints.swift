//
//  URLRequest+Endpoints.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-02.
//

import Foundation
import BloomModel

extension URLRequest {

  static func get(_ path: String) async -> URLRequest {
    let base = await APIHost.shared.resolvedHost
    return URLRequest(url: base.appendingPathComponent(path))
  }

  static func post(_ path: String, body: Encodable) async throws -> URLRequest {
    let base = await APIHost.shared.resolvedHost
    return try URLRequest(url: base.appendingPathComponent(path)).encoding(body: body)
  }
}

extension URLRequest {
  enum Auth {
    static func signIn(body: AuthenticationRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/auth/sign-in", body: body)
    }
  }
}

extension URLRequest {
  enum User {
    static func identify(body: AuthIdentifyRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/user/identify", body: body)
    }

    static func logout() async -> URLRequest {
      await URLRequest.get("v1/user/logout")
    }
    static func deleteAccount() async -> URLRequest {
      await URLRequest.get("v1/user/delete-account")
    }
  }
}

extension URLRequest {
  enum Food {
    static func autocomplete(body: FoodAutocompleteRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/autocomplete", body: body)
    }
    static func search(body: FoodSearchRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/search", body: body)
    }
    static func uploadFood(body: UploadNewFoodRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/upload", body: body)
    }
    static func estimateFood(body: EstimateFoodCaloriesRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/estimate", body: body)
    }
    static func markAsInaccurate(body: MarkFoodInaccurateRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/mark-as-inaccurate", body: body)
    }
    static func submitFoodItemIssue(body: SubmitFoodItemIssueRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/submit-food-item-issue", body: body)
    }
  }
}

extension URLRequest {
  enum Chat {
    static func sendMessage(body: ChatMessageRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/chat/new-message", body: body)
    }
    static func deleteChatThread() async throws -> URLRequest {
      await URLRequest.get("v1/chat/delete-thread")
    }
  }
}
