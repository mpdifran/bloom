//
//  USDAFoodSearchRequest.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import Foundation

public struct USDAFoodSearchRequest: Codable {
    public let query: String
    public let dataType: [String]
    public let pageSize: Int
    public let pageNumber: Int
    public let sortBy: String
    public let sortOrder: String

    public init(
        query: String,
        dataType: [String],
        pageSize: Int,
        pageNumber: Int,
        sortBy: String,
        sortOrder: String
    ) {
        self.query = query
        self.dataType = dataType
        self.pageSize = pageSize
        self.pageNumber = pageNumber
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }
}
