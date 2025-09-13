//
//  TrainingLoadCalculator.swift
//  CoreHealth
//
//  Created by Assistant on 2025-01-25.
//

import Foundation
import BloomFoundation

public final actor TrainingLoadCalculator {
  public static let shared = TrainingLoadCalculator()

  @AsyncStreamable public var trainingLoadSummary: TrainingLoadSummary?

  private init() { }
}

public extension TrainingLoadCalculator {

  func refreshTrainingLoad() async {
    // Only calculate if we don't have cached data
    if trainingLoadSummary == nil {
      await calculateTrainingLoad()
    }
  }

  func invalidateAndRecalculate() async {
    // Clear cached data and force recalculation
    trainingLoadSummary = nil
    await calculateTrainingLoad()
  }

  private func calculateTrainingLoad() async {
    trainingLoadSummary = await HealthStoreFetcher.shared.fetchTrainingLoadSummary()
  }
}