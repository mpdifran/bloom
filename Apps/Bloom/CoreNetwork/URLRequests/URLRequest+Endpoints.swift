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

  public static func post(_ path: String) async -> URLRequest {
    let base = await APIHost.shared.resolvedHost
    var request = URLRequest(url: base.appendingPathComponent(path))
    request.httpMethod = "POST"
    return request
  }

  static func websocket(_ path: String) async -> URLRequest {
    let base = await APIHost.shared.resolvedWebSocketHost
    return URLRequest(url: base.appendingPathComponent(path))
  }
}

public extension URLRequest {
  enum Auth {
    static func signIn(body: AuthenticationRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/auth/sign-in", body: body)
    }
  }
}

public extension URLRequest {
  public enum User {
    public static func identify(body: AuthIdentifyRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/user/identify", body: body)
    }
    public static func registerDeviceToken(body: RegisterUserPushNotificationTokenRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/user/register-device-token", body: body)
    }
    public static func testPushNotification() async -> URLRequest {
      await URLRequest.post("v1/user/test-push-notification")
    }
    public static func updateConsent(body: UpdateConsentRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/user/consent", body: body)
    }
    public static func getConsent() async -> URLRequest {
      await URLRequest.get("v1/user/consent")
    }
    public static func logout() async -> URLRequest {
      await URLRequest.get("v1/user/logout")
    }
    public static func deleteAccount() async -> URLRequest {
      await URLRequest.get("v1/user/delete-account")
    }
  }
}

public extension URLRequest {
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
    static func getById(foodId: String) async -> URLRequest {
      await URLRequest.get("v1/food/\(foodId)")
    }
    static func uploadMagicScan(body: MagicScanUploadRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/magic-scan-upload", body: body)
    }
    static func checkMagicScanStatus(body: MagicScanStatusRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/magic-scan-status", body: body)
    }
    static func cancelMagicScan(body: MagicScanCancelRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/food/magic-scan-cancel", body: body)
    }
  }
}

public extension URLRequest {
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

public extension URLRequest {
  enum Goals {
    static func suggestGoals(body: SuggestGoalsRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/goals/suggest", body: body)
    }
  }
}

public extension URLRequest {
  enum Workouts {
    public static func generatePlan(body: GenerateWorkoutPlanRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/workouts/generate-plan", body: body)
    }
  }
}

public extension URLRequest {
  enum Reports {
    static func getMorningHealthReport(body: MorningHealthReportRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/morning-report/generate", body: body)
    }
  }
}

public extension URLRequest {
  enum AI {
    static func getTodayView(body: TodayReportRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/today/insights", body: body)
    }
  }
}

public extension URLRequest {
  enum BiologicalAge {
    static func request(body: BiologicalAgeUploadRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/biological-age/request", body: body)
    }

    static func checkStatus() async throws -> URLRequest {
      try await URLRequest.post("v1/biological-age/status")
    }
  }
}

public extension URLRequest {
  enum Sales {
    static func getActiveSales() async -> URLRequest {
      await URLRequest.get("v1/sales/active")
    }
  }
}

public extension URLRequest {
  enum Monitor {
    public static func getSummary(body: MonitorSummaryRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/monitor/summary", body: body)
    }

    public static func getInsight(body: MonitorInsightRequest) async throws -> URLRequest {
      try await URLRequest.post("v1/monitor/insight", body: body)
    }
  }
}
