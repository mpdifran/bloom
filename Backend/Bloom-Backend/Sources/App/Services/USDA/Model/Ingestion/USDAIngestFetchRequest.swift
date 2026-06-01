//
//  USDAIngestFetchRequest.swift
//  Bloom-Backend
//

import Vapor

struct USDAIngestFetchRequest: Content {
    let kind: USDAImportFoodRequest.Kind
    let pageSize: Int
    let pageNumber: Int
}
