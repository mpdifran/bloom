//
//  URLRequest+Endpoints.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-02.
//

import Foundation
import BloomModel

public extension URLRequest {

  static func get(_ path: String) async -> URLRequest {
    let base = await APIHost.shared.resolvedHost
    return URLRequest(url: base.appendingPathComponent(path))
  }

  static func post(_ path: String, body: Encodable) async throws -> URLRequest {
    let base = await APIHost.shared.resolvedHost
    return try URLRequest(url: base.appendingPathComponent(path)).encoding(body: body)
  }

  static func websocket(_ path: String) async -> URLRequest {
    let base = await APIHost.shared.resolvedWebSocketHost
    return URLRequest(url: base.appendingPathComponent(path))
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
    static func registerDeviceToken(body: RegisterUserPushNotificationTokenRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/user/register-device-token", body: body)
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
    static func trackLog(body: TrackFoodLogRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/track-log", body: body)
    }
  }
}

extension URLRequest {
  enum Chat {
    static func reportHealthData(body: ChatReportHealthDataRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/chat/report-health-data", body: body)
    }
    static func sendMessage(body: ChatMessageRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/chat/new-message", body: body)
    }
    static func webSocket() async -> URLRequest {
      await URLRequest.websocket("v1/chat/web-socket")
    }
    static func submitToolCallResponse(body: SocketMessage.ToolCallsResponse) async throws -> URLRequest {
      try await URLRequest.post("v1/chat/submit-tool-call-response", body: body)
    }
    static func uploadImage(body: ChatUploadFileRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/chat/upload-image", body: body)
    }
    static func deleteChatThread() async -> URLRequest {
      await URLRequest.get("v1/chat/delete-thread")
    }
    static func reportIssue(body: SubmitChatMessageIssueRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/chat/report-issue", body: body)
    }
  }
}

extension URLRequest {
  enum Goals {
    static func suggestGoals(body: SuggestGoalsRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/goals/suggest", body: body)
    }
  }
}

extension URLRequest {
  enum Reports {
    static func getMorningHealthReport(body: MorningHealthReportRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/morning-report/generate", body: body)
    }
  }
}

extension URLRequest {
  enum AI {
    static func getTodayView(body: TodayReportRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/today/insights", body: body)
    }
  }
}

extension URLRequest {
  enum BiologicalAge {
    static func calculate(body: BiologicalAgeRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/biological-age/calculate", body: body)
    }
  }
}
