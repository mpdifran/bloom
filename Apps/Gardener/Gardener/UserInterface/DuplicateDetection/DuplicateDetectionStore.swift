//
//  DuplicateDetectionStore.swift
//  Gardener
//
//  Created by Assistant on 2025-09-09.
//

import AdminBloomModel
import Foundation
import SwiftUI

@MainActor
final class DuplicateDetectionStore: ObservableObject {
  @Published var duplicateGroups: [DuplicateGroup] = []
  @Published var selectedGroup: DuplicateGroup?
  @Published var isLoading = false
  @Published var isMarkingDistinct = false
  @Published var errorMessage: String?
  @Published var totalGroups = 0
  @Published var totalDuplicates = 0
  
  @Published var filterCategory: AdminFoodItemRecord.Category?
  @Published var filterState: AdminFoodItemRecord.State?
  @Published var minimumDuplicates = 2
  
  private let service = NetworkStack.shared
  private var currentOffset = 0
  private let pageSize = 50
  
  func loadDuplicateGroups() async {
    isLoading = true
    errorMessage = nil
    
    do {
      let response = try await service.getDuplicateGroups(
        limit: pageSize,
        offset: 0,
        minimumDuplicates: minimumDuplicates,
        category: filterCategory,
        state: filterState
      )
      
      duplicateGroups = response.groups
      totalGroups = response.totalGroups
      totalDuplicates = response.totalDuplicates
      currentOffset = 0
      
      if let firstGroup = duplicateGroups.first {
        selectedGroup = firstGroup
      }
    } catch {
      errorMessage = "Failed to load duplicate groups: \(error.localizedDescription)"
    }
    
    isLoading = false
  }
  
  func loadMoreGroups() async {
    guard !isLoading,
          currentOffset + pageSize < totalGroups else { return }
    
    isLoading = true
    
    do {
      let response = try await service.getDuplicateGroups(
        limit: pageSize,
        offset: currentOffset + pageSize,
        minimumDuplicates: minimumDuplicates,
        category: filterCategory,
        state: filterState
      )
      
      duplicateGroups.append(contentsOf: response.groups)
      currentOffset += pageSize
    } catch {
      errorMessage = "Failed to load more groups: \(error.localizedDescription)"
    }
    
    isLoading = false
  }
  
  func mergeFoodItems(
    primaryItem: AdminFoodItemRecord,
    itemsToMerge: [AdminFoodItemRecord],
    mergedData: AdminFoodItemRecord
  ) async throws {
    let request = MergeFoodItemsRequest(
      primaryItemId: primaryItem.id,
      itemsToMerge: itemsToMerge.map { $0.id },
      mergedItem: mergedData,
      deleteOthers: true
    )
    
    let response = try await service.mergeFoodItems(request: request)
    
    if response.success {
      if let groupIndex = duplicateGroups.firstIndex(where: { $0.id == primaryItem.id.value }) {
        duplicateGroups.remove(at: groupIndex)
        
        if let nextGroup = duplicateGroups.first {
          selectedGroup = nextGroup
        } else {
          selectedGroup = nil
        }
      }
    }
  }
  
  func markAsNotDuplicates(group: DuplicateGroup) async throws {
    isMarkingDistinct = true
    defer { isMarkingDistinct = false }
    
    // Mark all combinations in this group as distinct
    for duplicate in group.duplicates {
      let request = MarkItemsDistinctRequest(
        foodItemId: group.primaryItem.id,
        duplicateItemId: duplicate.item.id
      )
      
      let response = try await service.markItemsAsDistinct(request: request)
      
      if !response.success {
        throw NetworkError.serverError(statusCode: 400, errorResponse: nil)
      }
    }
    
    // Remove the group from the UI after successfully marking items as distinct
    if let index = duplicateGroups.firstIndex(where: { $0.id == group.id }) {
      duplicateGroups.remove(at: index)
      
      if duplicateGroups.isEmpty {
        selectedGroup = nil
      } else if selectedGroup?.id == group.id {
        selectedGroup = duplicateGroups.first
      }
    }
  }
  
  func selectNextGroup() {
    guard let currentGroup = selectedGroup,
          let currentIndex = duplicateGroups.firstIndex(where: { $0.id == currentGroup.id }),
          currentIndex < duplicateGroups.count - 1 else { return }
    
    selectedGroup = duplicateGroups[currentIndex + 1]
  }
  
  func selectPreviousGroup() {
    guard let currentGroup = selectedGroup,
          let currentIndex = duplicateGroups.firstIndex(where: { $0.id == currentGroup.id }),
          currentIndex > 0 else { return }
    
    selectedGroup = duplicateGroups[currentIndex - 1]
  }
}