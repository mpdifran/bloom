//
//  AdminBloomModel+Content.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-09-11.
//

import AdminBloomModel
import Vapor

// Mark AdminBloomModel response types as Vapor Content
extension RunDuplicateDetectionResponse: @retroactive Content { }

extension AdminWebDomainModel: @retroactive Content { }
extension AdminWebDomainListResponse: @retroactive Content { }
extension AdminWebDomainStatsResponse: @retroactive Content { }
extension AdminSetWebDomainVerdictRequest: @retroactive Content { }
