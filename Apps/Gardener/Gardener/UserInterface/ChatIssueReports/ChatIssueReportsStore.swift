//
//  ChatIssueReportsStore.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-06-11.
//

import AdminBloomModel
import Foundation

@MainActor
final class ChatIssueReportsStore: ObservableObject {
  static let shared = ChatIssueReportsStore()
  
  @Published var reports: [AdminChatIssueReport] = []
  @Published var isLoading = false
  @Published var error: Error?
  @Published var totalCount = 0
  
  private var currentOffset = 0
  private let limit = 50
  
  private init() {}
  
  func loadReports(refresh: Bool = false) async {
    if refresh {
      currentOffset = 0
      reports = []
    }
    
    isLoading = true
    error = nil
    
    do {
      let response = try await NetworkStack.shared.getChatIssueReports(
        limit: limit,
        offset: currentOffset
      )
      
      if refresh {
        reports = response.reports
      } else {
        reports.append(contentsOf: response.reports)
      }
      
      totalCount = response.totalCount
      currentOffset += response.reports.count
      
    } catch {
      self.error = error
    }
    
    isLoading = false
  }
  
  func loadMoreIfNeeded() async {
    guard !isLoading && reports.count < totalCount else { return }
    await loadReports(refresh: false)
  }
  
  func archiveReport(_ report: AdminChatIssueReport) async throws {
    do {
      let response = try await NetworkStack.shared.archiveChatIssueReport(reportID: report.id)
      
      // Update the local reports array with the archived report
      if let index = reports.firstIndex(where: { $0.id == report.id }) {
        reports[index] = response.report
        
        // Move archived report to the end of the list to match server sorting
        let archivedReport = reports.remove(at: index)
        reports.append(archivedReport)
      }
      
    } catch {
      self.error = error
      throw error
    }
  }
}