//
//  DuplicateDetection+Vapor.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-09-09.
//

import AdminBloomModel
import Vapor

extension DuplicateGroupsResponse: @retroactive Content { }
extension ItemDuplicatesResponse: @retroactive Content { }
extension MergeFoodItemsResponse: @retroactive Content { }
extension DuplicateGroupsRequest: @retroactive Content { }
extension ItemDuplicatesRequest: @retroactive Content { }
extension MergeFoodItemsRequest: @retroactive Content { }
