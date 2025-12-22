//
//  NetworkStack.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import AdminBloomModel
import Foundation

final class NetworkStack: Sendable {
  static let shared = NetworkStack()
}

private extension NetworkStack {
  enum Method: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
  }

  func createRequest(
    path: String,
    method: Method,
    queryItems: [URLQueryItem] = []
  ) -> URLRequest {
    let url = APIHost.shared.base
      .appendingPathComponent(path)
      .appending(queryItems: queryItems)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue

    return urlRequest
  }

  func createRequest<Content: Encodable>(
    path: String,
    method: Method,
    body: Content
  ) throws -> URLRequest {
    let url = APIHost.shared.base
      .appendingPathComponent(path)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(body)
    urlRequest.add(header: .contentTypeJSON)

    return urlRequest
  }

  func createAuthenticatedRequest(
    path: String,
    method: Method,
    queryItems: [URLQueryItem] = []
  ) async -> URLRequest {
    let url = APIHost.shared.base
      .appendingPathComponent(path)
      .appending(queryItems: queryItems)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue

    return await urlRequest.settingBloomHeaders()
  }

  func createAuthenticatedRequest<Content: Encodable>(
    path: String,
    method: Method,
    body: Content
  ) async throws -> URLRequest {
    let url = APIHost.shared.base
      .appendingPathComponent(path)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(body)
    urlRequest.add(header: .contentTypeJSON)

    return await urlRequest.settingBloomHeaders()
  }
}

extension NetworkStack {

  func login(request: AuthenticationRequest) async throws -> AuthenticationResponse {
    let urlRequest = try createRequest(
      path: "v1/admin/auth/sign-in",
      method: .post,
      body: request
    )
    
    let (data, _) = try await URLSession.shared.data(for: urlRequest)
    
    return try JSONDecoder.bloomModel.decode(AuthenticationResponse.self, from: data)
  }

  func logout() async throws {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/user/logout",
      method: .get
    )

    _ = try await URLSession.shared.data(for: urlRequest)
  }

  func getUnverifiedFoodRecords(
    limit: Int = 100
  ) async throws -> UnverifiedFoodItemsResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/unverified",
      method: .get,
      queryItems: [.init(name: "limit", value: "\(limit)")]
    )

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(UnverifiedFoodItemsResponse.self, from: data)
  }
  
  func createFoodRecord(
    request: AdminCreateFoodItemRequest
  ) async throws -> AdminCreateFoodItemResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/create",
      method: .post,
      body: request
    )
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(AdminCreateFoodItemResponse.self, from: data)
  }

  func updateFoodRecord(
    request: AdminUpdateFoodItemRequest
  ) async throws -> AdminUpdateFoodItemResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/update",
      method: .patch,
      body: request
    )

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(AdminUpdateFoodItemResponse.self, from: data)
  }

  func deleteFoodRecord(id: FoodItemIdentifier) async throws {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/" + id.value,
      method: .delete
    )

    _ = try await URLSession.shared.data(for: urlRequest)
  }

  func searchFoodRecord(query: String) async throws -> AdminSearchFoodItemResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/search",
      method: .get,
      queryItems: [.init(name: "query", value: "\(query)")]
    )

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(AdminSearchFoodItemResponse.self, from: data)
  }

  func bulkUploadOpenFoodFacts(request: AdminOpenFoodFactsBulkUploadRequest) async throws -> AdminOpenFoodFactsBulkUploadResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/open-food-facts/bulk-upload",
      method: .post,
      body: request
    )

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(AdminOpenFoodFactsBulkUploadResponse.self, from: data)
  }
  
  func getLatestAccuracyReport(
    forFoodItemWithID id: FoodItemIdentifier
  ) async throws -> AdminAccuracyReportGetResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/accuracy-report",
      method: .get,
      queryItems: [.init(name: "food_item_record_id", value: "\(id.value)")]
    )
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(AdminAccuracyReportGetResponse.self, from: data)
  }
  
  func regenerateAccuracyReport(
    forFoodItemWithID id: FoodItemIdentifier
  ) async throws -> AdminAccuracyReportGetResponse {
    let request = AdminRegenerateAccuracyReportRequest(foodItemRecordID: id)
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/regenerate-accuracy-report",
      method: .post,
      body: request
    )
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(AdminAccuracyReportGetResponse.self, from: data)
  }
  
  func getChatIssueReports(
    limit: Int = 100,
    offset: Int = 0
  ) async throws -> AdminChatIssueReportsResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/chat/issue-reports",
      method: .get,
      queryItems: [
        .init(name: "limit", value: "\(limit)"),
        .init(name: "offset", value: "\(offset)")
      ]
    )

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(AdminChatIssueReportsResponse.self, from: data)
  }
  
  func getChatIssueReportMessages(
    reportID: String
  ) async throws -> AdminChatIssueReportMessagesResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/chat/issue-reports/\(reportID)/messages",
      method: .get
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(AdminChatIssueReportMessagesResponse.self, from: data)
  }
  
  func archiveChatIssueReport(
    reportID: String
  ) async throws -> AdminArchiveChatIssueReportResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/chat/issue-reports/\(reportID)/archive",
      method: .patch
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(AdminArchiveChatIssueReportResponse.self, from: data)
  }
  
  func getDuplicateGroups(
    limit: Int = 50,
    offset: Int = 0,
    minimumDuplicates: Int = 2,
    category: AdminFoodItemRecord.Category? = nil,
    state: AdminFoodItemRecord.State? = nil
  ) async throws -> DuplicateGroupsResponse {
    var queryItems = [
      URLQueryItem(name: "limit", value: "\(limit)"),
      URLQueryItem(name: "offset", value: "\(offset)"),
      URLQueryItem(name: "minimumDuplicates", value: "\(minimumDuplicates)")
    ]
    
    if let category = category {
      queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
    }
    
    if let state = state {
      queryItems.append(URLQueryItem(name: "state", value: state.rawValue))
    }
    
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/duplicates/groups",
      method: .get,
      queryItems: queryItems
    )
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    try await Self.checkStatusCode(data: data, response: response)
    
    return try JSONDecoder.bloomModel.decode(DuplicateGroupsResponse.self, from: data)
  }
  
  func getDuplicatesForItem(
    foodID: FoodItemIdentifier,
    similarityThreshold: Double = 0.3,
    limit: Int = 20
  ) async throws -> ItemDuplicatesResponse {
    let queryItems = [
      URLQueryItem(name: "similarityThreshold", value: "\(similarityThreshold)"),
      URLQueryItem(name: "limit", value: "\(limit)")
    ]
    
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/duplicates/\(foodID.value)",
      method: .get,
      queryItems: queryItems
    )
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    try await Self.checkStatusCode(data: data, response: response)
    
    return try JSONDecoder.bloomModel.decode(ItemDuplicatesResponse.self, from: data)
  }
  
  func mergeFoodItems(request: MergeFoodItemsRequest) async throws -> MergeFoodItemsResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/duplicates/merge",
      method: .post,
      body: request
    )
    
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    
    try await Self.checkStatusCode(data: data, response: response)
    
    return try JSONDecoder.bloomModel.decode(MergeFoodItemsResponse.self, from: data)
  }
  
  func markItemsAsDistinct(request: MarkItemsDistinctRequest) async throws -> MarkItemsDistinctResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/duplicates/mark-distinct",
      method: .post,
      body: request
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(MarkItemsDistinctResponse.self, from: data)
  }

  // MARK: - Food Item Issue Reports

  func getIssueReports(
    forFoodItemID foodItemID: FoodItemIdentifier
  ) async throws -> [AdminFoodItemIssueReport] {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/issue-reports",
      method: .get,
      queryItems: [.init(name: "food_item_record_id", value: foodItemID.value)]
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    let responseBody = try JSONDecoder.bloomModel.decode(AdminFoodItemIssueReportsResponse.self, from: data)
    return responseBody.issueReports
  }

  func applyIssueReport(
    reportID: String,
    foodItemID: FoodItemIdentifier,
    fieldsToApply: [String]
  ) async throws {
    let request = AdminApplyIssueReportRequest(
      issueReportID: reportID,
      foodItemRecordID: foodItemID,
      fieldsToApply: fieldsToApply
    )

    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/issue-reports/apply",
      method: .post,
      body: request
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)
  }

  func deleteIssueReport(reportID: String) async throws {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/issue-reports/\(reportID)",
      method: .delete
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)
  }

  // MARK: - Storage Management

  func getStorageStats() async throws -> GetStorageStatsResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/storage/stats",
      method: .get
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(GetStorageStatsResponse.self, from: data)
  }

  func getOrphanedImages() async throws -> GetOrphanedImagesResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/storage/orphaned-images",
      method: .get
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(GetOrphanedImagesResponse.self, from: data)
  }

  func deleteOrphanedImages(request: DeleteOrphanedImagesRequest) async throws -> DeleteOrphanedImagesResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/storage/orphaned-images",
      method: .delete,
      body: request
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(DeleteOrphanedImagesResponse.self, from: data)
  }

  func getLargeImages(thresholdBytes: Int64 = 512_000) async throws -> GetLargeImagesResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/storage/large-images",
      method: .get,
      queryItems: [.init(name: "thresholdBytes", value: "\(thresholdBytes)")]
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(GetLargeImagesResponse.self, from: data)
  }

  func generatePresignedURL(request: GeneratePresignedURLRequest) async throws -> URL {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/storage/generate-presigned-url",
      method: .post,
      body: request
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    let urlResponse = try JSONDecoder.bloomModel.decode(GeneratePresignedURLResponse.self, from: data)
    return urlResponse.url
  }

  func replaceImage(request: ReplaceImageRequest) async throws {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/storage/replace-image",
      method: .post,
      body: request
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)
  }

  // MARK: - Sales

  func getAllSales() async throws -> AdminSalesListResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/sales",
      method: .get
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(AdminSalesListResponse.self, from: data)
  }

  func createSale(request: AdminCreateSaleRequest) async throws -> AdminSaleResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/sales/create",
      method: .post,
      body: request
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(AdminSaleResponse.self, from: data)
  }

  func updateSale(request: AdminUpdateSaleRequest) async throws -> AdminSaleResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/sales/update",
      method: .patch,
      body: request
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(AdminSaleResponse.self, from: data)
  }

  func deleteSale(id: String) async throws {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/sales/\(id)",
      method: .delete
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)
  }

  func uploadSaleImage(request: AdminUploadSaleImageRequest) async throws -> AdminUploadSaleImageResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/sales/\(request.saleId)/upload-image",
      method: .post,
      body: request
    )

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    try await Self.checkStatusCode(data: data, response: response)

    return try JSONDecoder.bloomModel.decode(AdminUploadSaleImageResponse.self, from: data)
  }

  private static func checkStatusCode(data: Data, response: URLResponse) async throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw NetworkError.invalidResponse
    }

    if !(200...299).contains(httpResponse.statusCode) {
      // Try to decode the error message
      let errorResponse = try? JSONDecoder.bloomModel.decode(NetworkErrorResponse.self, from: data)
      throw NetworkError.serverError(statusCode: httpResponse.statusCode, errorResponse: errorResponse)
    }
  }
}
