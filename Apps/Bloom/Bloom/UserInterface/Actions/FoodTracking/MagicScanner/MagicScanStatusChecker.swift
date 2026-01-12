//
//  MagicScanStatusChecker.swift
//  Bloom
//
//  Created by Claude on 2025-10-25.
//

import Foundation
import SwiftData
import CoreNetwork
import CoreHealth
import DataContainer
import TelemetryDeck
import BloomModel

@MainActor
final class MagicScanStatusChecker {
  static let shared = MagicScanStatusChecker()

  private init() {}

  /// Checks the status of pending/processing Magic Scanner items
  func checkPendingItems(modelContext: ModelContext) async {
    // Split into 2 simple queries to avoid slow type-checking from || in predicate
    let pendingState = "pending"
    let processingState = "processing"

    let pendingDescriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate { $0.processingStateRawValue == pendingState }
    )
    let processingDescriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate { $0.processingStateRawValue == processingState }
    )

    let pendingLogs = (try? modelContext.fetch(pendingDescriptor)) ?? []
    let processingLogs = (try? modelContext.fetch(processingDescriptor)) ?? []
    let allPendingLogs = pendingLogs + processingLogs

    guard !allPendingLogs.isEmpty else {
      return
    }

    // Collect processing identifiers
    let processingIdentifiers = allPendingLogs.compactMap { identifier in
      identifier.processingIdentifier.map { AIFoodProcessingIdentifier($0) }
    }

    guard !processingIdentifiers.isEmpty else {
      return
    }

    // Check status with backend
    await checkStatus(processingIdentifiers: processingIdentifiers)
  }

  /// Checks the status of specific processing identifiers
  func checkStatus(processingIdentifiers: [AIFoodProcessingIdentifier]) async {
    guard !processingIdentifiers.isEmpty else {
      return
    }

    do {
      let response = try await NetworkRequester.shared.checkMagicScanStatus(
        processingIdentifiers: processingIdentifiers
      )

      // Process each result
      for result in response.results {
        await handleStatusResult(result)
      }
    } catch {
      TelemetryDeck.errorOccurred(
        id: "MagicScanStatusChecker.checkStatus",
        category: .thrownException,
        message: error.localizedDescription
      )
      print("Error checking magic scan status:", error)
    }
  }

  private func handleStatusResult(_ result: MagicScanStatusResponse.Result) async {
    // Get model context from main app
    let modelContext = ModelContext(ContainerHolder.shared.container)

    switch result.status {
    case .completed:
      // Convert servings to FoodItemServingAmount
      let servings = result.servings?.map { $0.asServing() } ?? []

      // If no food was detected, treat as an error
      if servings.isEmpty {
        do {
          try await NutritionTrackingViewModel.shared.failMagicScan(
            modelContext: modelContext,
            processingIdentifier: result.processingIdentifier,
            errorMessage: "Couldn't detect any food in this image"
          )
        } catch {
          print("Error failing magic scan:", error)
        }
      } else {
        do {
          try await NutritionTrackingViewModel.shared.completeMagicScan(
            modelContext: modelContext,
            processingIdentifier: result.processingIdentifier,
            servings: servings
          )
        } catch {
          print("Error completing magic scan:", error)
        }
      }

    case .failed:
      let errorMessage = result.errorMessage ?? "Processing failed"

      do {
        try await NutritionTrackingViewModel.shared.failMagicScan(
          modelContext: modelContext,
          processingIdentifier: result.processingIdentifier,
          errorMessage: errorMessage
        )
      } catch {
        print("Error failing magic scan:", error)
      }

    case .cancelled:
      do {
        try await NutritionTrackingViewModel.shared.failMagicScan(
          modelContext: modelContext,
          processingIdentifier: result.processingIdentifier,
          errorMessage: "Scan cancelled"
        )
      } catch {
        print("Error failing magic scan:", error)
      }

    case .notFound:
      // Backend doesn't have this job - need to re-upload
      let identifierValue = result.processingIdentifier.value
      let descriptor = FetchDescriptor<FoodItemLog>(
        predicate: #Predicate { $0.processingIdentifier == identifierValue }
      )

      guard let foodItemLog = try? modelContext.fetch(descriptor).first else {
        return
      }

      // Re-upload using the retry mechanism
      do {
        try await NutritionTrackingViewModel.shared.retryMagicScan(
          modelContext: modelContext,
          foodItemLog: foodItemLog
        )
      } catch {
        print("Error retrying magic scan after notFound status:", error)
        // If retry fails, mark as failed
        try? await NutritionTrackingViewModel.shared.failMagicScan(
          modelContext: modelContext,
          processingIdentifier: result.processingIdentifier,
          errorMessage: "Failed to re-upload: \(error.localizedDescription)"
        )
      }

    case .pending, .processing:
      // Update state to processing if it was pending
      let identifierValue = result.processingIdentifier.value
      let descriptor = FetchDescriptor<FoodItemLog>(
        predicate: #Predicate { $0.processingIdentifier == identifierValue }
      )

      guard let foodItemLog = try? modelContext.fetch(descriptor).first else {
        return
      }

      if foodItemLog.processingState == .pending {
        try? modelContext.savingTransaction {
          foodItemLog.processingState = .processing
        }
      }
    }
  }
}
