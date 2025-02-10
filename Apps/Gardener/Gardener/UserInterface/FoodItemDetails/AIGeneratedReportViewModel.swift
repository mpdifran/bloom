//
//  AIGeneratedReportViewModel.swift
//  Gardener
//
//  Created by Haocen Jiang on 2025-02-08.
//

import AdminBloomModel
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AIGeneratedReportViewModel: ObservableObject {
  enum ReportState {
    case notApplicable // for cases like the create food item flow
    case pendingFetch
    case fetching
    case noReportAvailable
    case fetched(AdminAccuracyReport)
  }
  
  struct Disclaimer {
    let text: String
    let color: Color
  }
  
  init(
    foodItemRecord: AdminFoodItemRecord,
    shouldFetchReport: Bool
  ) {
    self.foodItemRecord = foodItemRecord
    
    if shouldFetchReport {
      accuracyReportState = .pendingFetch
    } else {
      accuracyReportState = .notApplicable
    }
  }
  
  @Published var accuracyReportState: ReportState
  @Published var disclaimer: Disclaimer?
  private var foodItemRecord: AdminFoodItemRecord {
    didSet {
      Task { @MainActor in updateDisclaimer() }
    }
  }

  func fetchAccuracyReport() async {
    if case .notApplicable = accuracyReportState { return }
    do {
      let response = try await NetworkStack.shared.getLatestAccuracyReport(forFoodItemWithID: foodItemRecord.id)

      await MainActor.run {
        if let report = response.report {
          accuracyReportState = .fetched(report)
          updateDisclaimer()
        } else {
          accuracyReportState = .noReportAvailable
        }
      }
    } catch {
      await MainActor.run { accuracyReportState = .noReportAvailable }
    }
  }
  
  func setCurrentFoodRecord(to newRecord: AdminFoodItemRecord) {
    foodItemRecord = newRecord
  }
  
  /// Caller should make sure this is on main
  func updateDisclaimer() {
    guard case .fetched(let adminAccuracyReport) = accuracyReportState else { return }

    guard let reportCreatedAt = adminAccuracyReport.createdAt,
          let foodItemUpdatedAt = foodItemRecord.updatedAt else { return }
    
    let formattedReportCreatedAt = reportCreatedAt.formatted(date: .abbreviated, time: .omitted)
    
    if reportCreatedAt >= foodItemUpdatedAt {
      disclaimer = .init(text: "Report generated on \(formattedReportCreatedAt)", color: .primary)
    } else {
      disclaimer = .init(
        text: "Report generated on \(formattedReportCreatedAt). Food record was updated since then",
        color: .red
      )
    }
  }
  
  // In the future, consider making the report generation async on the BE
  // and use polling/web socket/SSE to get report status updates
  func regenerateReport() async {
    await MainActor.run {
      accuracyReportState = .fetching
      updateDisclaimer()
    }
    do {
      let response = try await NetworkStack.shared.regenerateAccuracyReport(forFoodItemWithID: foodItemRecord.id)
      
      await MainActor.run {
        if let report = response.report {
          accuracyReportState = .fetched(report)
          updateDisclaimer()
        } else {
          accuracyReportState = .noReportAvailable
          updateDisclaimer()
        }
      }
    } catch {
      await MainActor.run {
        accuracyReportState = .noReportAvailable
        updateDisclaimer()
      }
    }
  }
}
