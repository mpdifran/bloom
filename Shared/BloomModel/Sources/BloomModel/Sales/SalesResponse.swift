//
//  SalesResponse.swift
//  bloom-model
//
//  Created by Claude on 2025-12-02.
//

public struct SalesResponse: Codable, Equatable, Sendable {
  public let sales: [SaleDetails]

  public init(sales: [SaleDetails]) {
    self.sales = sales
  }
}
