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
