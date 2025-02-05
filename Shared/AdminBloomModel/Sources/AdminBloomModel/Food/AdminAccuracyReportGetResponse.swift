//
//  AdminAccuracyReportGetResponse.swift
//  admin-bloom-model
//
//  Created by Haocen Jiang on 2025-02-04.
//

import Foundation

public struct AdminAccuracyReport: Codable, Sendable {
  public let accuracyScore: Double
  public let evaluationNotes: String?
  public let createdAt: Date?
  
  public init(accuracyScore: Double, evaluationNotes: String?, createdAt: Date?) {
    self.accuracyScore = accuracyScore
    self.evaluationNotes = evaluationNotes
    self.createdAt = createdAt
  }
}

public struct AdminAccuracyReportGetResponse: Codable, Sendable {
  public let report: AdminAccuracyReport?
  
  public init(report: AdminAccuracyReport?) {
    self.report = report
  }
}
