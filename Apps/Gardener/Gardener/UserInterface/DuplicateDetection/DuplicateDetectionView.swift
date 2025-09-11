//
//  DuplicateDetectionView.swift
//  Gardener
//
//  Created by Assistant on 2025-09-09.
//

import AdminBloomModel
import SwiftUI

struct DuplicateDetectionView: View {
  @StateObject private var store = DuplicateDetectionStore()
  @State private var selectedDuplicates: Set<String> = []
  @State private var showMergeSheet = false
  
  var body: some View {
    HStack(spacing: 0) {
      // Sidebar - List of duplicate groups
      duplicateGroupsList
        .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
      
      Divider()
      
      // Content - Duplicate candidates for selected group
      if let selectedGroup = store.selectedGroup {
        duplicateCandidatesList(for: selectedGroup)
          .frame(minWidth: 300, idealWidth: 400, maxWidth: 500)
      } else {
        ContentUnavailableView(
          "No Group Selected",
          systemImage: "square.on.square",
          description: Text("Select a duplicate group to view candidates")
        )
        .frame(maxWidth: .infinity)
      }
      
      Divider()
      
      // Detail - Comparison view
      if let selectedGroup = store.selectedGroup,
         !selectedDuplicates.isEmpty {
        comparisonView(for: selectedGroup)
          .frame(minWidth: 400, idealWidth: 600)
      } else {
        ContentUnavailableView(
          "No Items Selected",
          systemImage: "square.split.2x2",
          description: Text("Select items to compare")
        )
        .frame(maxWidth: .infinity)
      }
    }
    .navigationTitle("Duplicate Detection")
    .task {
      await store.loadDuplicateGroups()
    }
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        filterMenu
        
        Button {
          Task {
            await store.loadDuplicateGroups()
          }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
        .disabled(store.isLoading)
        .keyboardShortcut("r", modifiers: .command)
      }
    }
    .sheet(isPresented: $showMergeSheet) {
      if let selectedGroup = store.selectedGroup {
        MergeFoodItemsView(
          store: store,
          group: selectedGroup,
          selectedItems: Array(selectedDuplicates.compactMap { id in
            selectedGroup.duplicates.first { $0.id == id }?.item
          })
        )
      }
    }
    .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
      Button("OK") {
        store.errorMessage = nil
      }
    } message: {
      if let errorMessage = store.errorMessage {
        Text(errorMessage)
      }
    }
  }
}

private extension DuplicateDetectionView {
  var duplicateGroupsList: some View {
    List(selection: $store.selectedGroupID) {
      ForEach(store.duplicateGroups) { group in
        DuplicateGroupRow(group: group)
          .tag(group.id)
      }
      
      if store.duplicateGroups.count < store.totalGroups {
        ProgressView()
          .frame(maxWidth: .infinity)
          .task {
            await store.loadMoreGroups()
          }
      }
    }
    .listStyle(.sidebar)
    .overlay {
      if store.isLoading && store.duplicateGroups.isEmpty {
        ProgressView("Loading duplicate groups...")
      } else if store.duplicateGroups.isEmpty {
        ContentUnavailableView(
          "No Duplicates Found",
          systemImage: "checkmark.circle",
          description: Text("No duplicate food items were found with the current filters")
        )
      }
    }
  }
  
  func duplicateCandidatesList(for group: DuplicateGroup) -> some View {
    List(selection: $selectedDuplicates) {
      Section("Primary Item") {
        FoodItemRow(item: group.primaryItem, isPrimary: true)
          .tag(group.primaryItem.id.value)
      }
      
      Section("Potential Duplicates (\(group.duplicates.count))") {
        ForEach(group.duplicates) { candidate in
          DuplicateCandidateRow(candidate: candidate)
            .tag(candidate.id)
        }
      }
    }
    .listStyle(.inset)
    .toolbar {
      ToolbarItemGroup(placement: .secondaryAction) {
        Button("Merge Selected") {
          showMergeSheet = true
        }
        .disabled(selectedDuplicates.isEmpty)
        
        Button {
          Task {
            do {
              try await store.markAsNotDuplicates(group: group)
              selectedDuplicates.removeAll()
            } catch {
              store.errorMessage = "Failed to mark items as distinct: \(error.localizedDescription)"
            }
          }
        } label: {
          HStack {
            if store.isMarkingDistinct {
              ProgressView()
                .scaleEffect(0.8)
            }
            Text("Not Duplicates")
          }
        }
        .disabled(store.isMarkingDistinct)
      }
    }
    .onChange(of: store.selectedGroupID) { _, _ in
      selectedDuplicates.removeAll()
    }
  }
  
  func comparisonView(for group: DuplicateGroup) -> some View {
    ScrollView {
      VStack(spacing: 20) {
        if selectedDuplicates.contains(group.primaryItem.id.value) {
          FoodItemComparisonCard(
            item: group.primaryItem,
            title: "Primary Item",
            isPrimary: true
          )
        }
        
        ForEach(group.duplicates.filter { selectedDuplicates.contains($0.id) }) { candidate in
          FoodItemComparisonCard(
            item: candidate.item,
            title: "Duplicate (Score: \(String(format: "%.1f%%", candidate.similarityScore * 100)))",
            isPrimary: false,
            matchTypes: candidate.matchTypes
          )
        }
      }
      .padding()
    }
  }
  
  var filterMenu: some View {
    Menu {
      Menu("Category") {
        Button("All") {
          store.filterCategory = nil
        }
        ForEach(AdminFoodItemRecord.Category.allCases, id: \.self) { category in
          Button(category.rawValue.capitalized) {
            store.filterCategory = category
          }
        }
      }
      
      Menu("State") {
        Button("All") {
          store.filterState = nil
        }
        ForEach(AdminFoodItemRecord.State.allCases, id: \.self) { state in
          Button(state.name) {
            store.filterState = state
          }
        }
      }
      
      Menu("Minimum Duplicates") {
        ForEach([2, 3, 4, 5, 10], id: \.self) { count in
          Button("\(count)+") {
            store.minimumDuplicates = count
            Task {
              await store.loadDuplicateGroups()
            }
          }
        }
      }
    } label: {
      Image(systemName: "line.3.horizontal.decrease.circle")
    }
  }
}

struct DuplicateGroupRow: View {
  let group: DuplicateGroup
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(group.primaryItem.name ?? "Unknown")
        .font(.headline)
        .lineLimit(1)
      
      if let brand = group.primaryItem.brandName {
        Text(brand)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      
      HStack {
        Label("\(group.totalCount) items", systemImage: "square.on.square")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(group.primaryItem.state.name)
          .font(.caption2)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(stateColor(for: group.primaryItem.state).opacity(0.2))
          .foregroundStyle(stateColor(for: group.primaryItem.state))
          .clipShape(Capsule())
      }
    }
    .padding(.vertical, 4)
  }
  
  func stateColor(for state: AdminFoodItemRecord.State) -> Color {
    switch state {
    case .verified:
      return .green
    case .unverified:
      return .orange
    case .needsMoreInfo:
      return .yellow
    case .needsAIProcessing:
      return .purple
    }
  }
}

struct FoodItemRow: View {
  let item: AdminFoodItemRecord
  let isPrimary: Bool
  
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(item.name ?? "Unknown")
          .font(.headline)
        
        if let brand = item.brandName {
          Text(brand)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
      
      Spacer()
      
      if isPrimary {
        Image(systemName: "star.fill")
          .foregroundStyle(.yellow)
      }
    }
    .padding(.vertical, 4)
  }
}

struct DuplicateCandidateRow: View {
  let candidate: DuplicateCandidate
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(candidate.item.name ?? "Unknown")
          .font(.headline)
        
        Spacer()
        
        Text("\(Int(candidate.similarityScore * 100))%")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      if let brand = candidate.item.brandName {
        Text(brand)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      
      HStack {
        ForEach(candidate.matchTypes, id: \.self) { matchType in
          Text(matchType.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.2))
            .clipShape(Capsule())
        }
      }
    }
    .padding(.vertical, 4)
  }
}

struct FoodItemComparisonCard: View {
  let item: AdminFoodItemRecord
  let title: String
  let isPrimary: Bool
  var matchTypes: [MatchType] = []
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(title)
          .font(.headline)
        
        if isPrimary {
          Image(systemName: "star.fill")
            .foregroundStyle(.yellow)
        }
        
        Spacer()
        
        ForEach(matchTypes, id: \.self) { matchType in
          Text(matchType.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.2))
            .clipShape(Capsule())
        }
      }
      
      Divider()
      
      Group {
        DetailRow(label: "Name", value: item.name)
        DetailRow(label: "Brand", value: item.brandName)
        DetailRow(label: "Flavor", value: item.flavour)
        DetailRow(label: "Barcode", value: item.barcode)
        DetailRow(label: "State", value: item.state.name)
      }
      
      Divider()
      
      Group {
        DetailRow(label: "Calories", value: item.calories.map { "\($0)" })
        DetailRow(label: "Protein", value: item.protein.map { "\($0)g" })
        DetailRow(label: "Carbs", value: item.carbohydrates.map { "\($0)g" })
        DetailRow(label: "Fat", value: item.fat.map { "\($0)g" })
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

struct DetailRow: View {
  let label: String
  let value: String?
  
  var body: some View {
    HStack {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 100, alignment: .leading)
      
      Text(value ?? "—")
        .font(.body)
        .textSelection(.enabled)
    }
  }
}

#Preview {
  DuplicateDetectionView()
}