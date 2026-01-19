//
//  BloomModel+Content.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import AdminBloomModel
import BloomModel
import Vapor

extension AdminSearchFoodItemResponse: @retroactive Content { }
extension AdminUpdateFoodItemRequest: @retroactive Content { }
extension AdminUpdateFoodItemResponse: @retroactive Content { }
extension EstimateFoodCaloriesRequest: @retroactive Content { }
extension EstimateFoodCaloriesResponse: @retroactive Content { }
extension FoodAutocompleteRequest: @retroactive Content { }
extension FoodAutocompleteResponse: @retroactive Content { }
extension FoodSearchRequest: @retroactive Content { }
extension FoodSearchResponse: @retroactive Content { }
extension UploadNewFoodRequest: @retroactive Content { }
extension UploadNewFoodResponse: @retroactive Content { }
extension UnverifiedFoodItemsResponse: @retroactive Content { }
extension AuthenticationRequest: @retroactive Content { }
extension AuthenticationResponse: @retroactive Content { }
extension AdminOpenFoodFactsBulkUploadRequest: @retroactive Content { }
extension AdminOpenFoodFactsBulkUploadResponse: @retroactive Content { }
extension AuthIdentifyRequest: @retroactive Content { }
extension AuthIdentifyResponse: @retroactive Content { }
extension AdminCreateFoodItemResponse: @retroactive Content { }
extension AdminAccuracyReportGetResponse: @retroactive Content { }
extension AdminRegenerateAccuracyReportRequest: @retroactive Content { }
extension ChatMessageRequest: @retroactive Content { }
extension ChatMessageResponse: @retroactive Content { }
extension SuggestGoalsResponse: @retroactive Content { }
extension ChatUploadFileRequest: @retroactive Content { }
extension ChatUploadFileResponse: @retroactive Content { }
extension AdminChatIssueReportsResponse: @retroactive Content { }
extension AdminChatIssueReportMessagesResponse: @retroactive Content { }
extension AdminArchiveChatIssueReportRequest: @retroactive Content { }
extension AdminArchiveChatIssueReportResponse: @retroactive Content { }
extension MorningHealthReportResponse: @retroactive Content { }
extension TodayReportRequest: @retroactive Content { }
extension TodayReportResponse: @retroactive Content { }
extension BiologicalAgeRequest: @retroactive Content { }
extension BiologicalAgeResponse: @retroactive Content { }
extension BiologicalAgeUploadRequest: @retroactive Content { }
extension BiologicalAgeUploadResponse: @retroactive Content { }
extension BiologicalAgeStatusResponse: @retroactive Content { }
extension GetFoodItemResponse: @retroactive Content { }
extension MagicScanUploadRequest: @retroactive Content { }
extension MagicScanUploadResponse: @retroactive Content { }
extension MagicScanStatusRequest: @retroactive Content { }
extension MagicScanStatusResponse: @retroactive Content { }
extension MagicScanCancelRequest: @retroactive Content { }
extension MagicScanCompleteTrigger: @retroactive Content { }
extension UpdateConsentRequest: @retroactive Content { }
extension ConsentResponse: @retroactive Content { }
extension GetStorageStatsResponse: @retroactive Content { }
extension GetOrphanedImagesResponse: @retroactive Content { }
extension DeleteOrphanedImagesRequest: @retroactive Content { }
extension DeleteOrphanedImagesResponse: @retroactive Content { }
extension GetLargeImagesRequest: @retroactive Content { }
extension GetLargeImagesResponse: @retroactive Content { }
extension GeneratePresignedURLRequest: @retroactive Content { }
extension GeneratePresignedURLResponse: @retroactive Content { }
extension ReplaceImageRequest: @retroactive Content { }
extension SalesResponse: @retroactive Content { }
extension AdminSalesListResponse: @retroactive Content { }
extension AdminSaleResponse: @retroactive Content { }
extension AdminUploadSaleImageResponse: @retroactive Content { }
extension AdminFoodItemIssueReportsResponse: @retroactive Content { }
extension AdminApplyIssueReportRequest: @retroactive Content { }
extension AdminApplyIssueReportResponse: @retroactive Content { }
extension MonitorSummaryRequest: @retroactive Content { }
extension MonitorSummaryResponse: @retroactive Content { }
extension MonitorInsightRequest: @retroactive Content { }
extension MonitorInsightResponse: @retroactive Content { }
