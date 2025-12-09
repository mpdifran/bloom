//
//  SaleEligibilityState.swift
//  Bloom
//

import BloomModel
import Foundation

struct SaleEligibilityState: Equatable, Sendable {
  let isActive: Bool
  let isWithinDateRange: Bool
  let currentDate: Date
  let startDate: Date
  let endDate: Date
  let userAudienceMatches: Bool
  let userAudienceType: TargetAudience
  let targetAudiences: [TargetAudience]
  let displayFrequencyMet: Bool
  let displayFrequencyDays: Int
  let daysSinceLastShown: Int?

  var meetsAllCriteria: Bool {
    isActive && isWithinDateRange && userAudienceMatches && displayFrequencyMet
  }
}
