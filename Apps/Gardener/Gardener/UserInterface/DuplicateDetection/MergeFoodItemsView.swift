//
//  MergeFoodItemsView.swift
//  Gardener
//
//  Created by Assistant on 2025-09-09.
//

import AdminBloomModel
import SwiftUI

struct MergeFoodItemsView: View {
  @ObservedObject var store: DuplicateDetectionStore
  let group: DuplicateGroup
  let selectedItems: [AdminFoodItemRecord]
  
  @State private var mergedItem: AdminFoodItemRecord
  @State private var isProcessing = false
  @State private var errorMessage: String?
  @Environment(\.dismiss) private var dismiss
  
  init(store: DuplicateDetectionStore, group: DuplicateGroup, selectedItems: [AdminFoodItemRecord]) {
    self.store = store
    self.group = group
    self.selectedItems = selectedItems
    self._mergedItem = State(initialValue: group.primaryItem)
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text("Merge \(selectedItems.count + 1) Food Items")
            .font(.largeTitle)
            .bold()
          
          Text("Review and select the data to keep for the merged item. The primary item will be updated and other items will be deleted.")
            .foregroundStyle(.secondary)
          
          if let errorMessage = errorMessage {
            Text(errorMessage)
              .foregroundStyle(.red)
              .padding()
              .background(Color.red.opacity(0.1))
              .clipShape(RoundedRectangle(cornerRadius: 8))
          }
          
          mergeFieldsSection
        }
        .padding()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Merge") {
            Task {
              await performMerge()
            }
          }
          .disabled(isProcessing)
        }
      }
      .disabled(isProcessing)
      .overlay {
        if isProcessing {
          ZStack {
            Color.black.opacity(0.3)
            ProgressView("Merging items...")
              .padding()
              .background(Color.gray.opacity(0.9))
              .clipShape(RoundedRectangle(cornerRadius: 10))
          }
        }
      }
    }
  }
  
  private var mergeFieldsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Basic Information")
        .font(.headline)
      
      MergeFieldPicker(
        label: "Name",
        value: $mergedItem.name,
        options: collectOptions(\.name),
        displayTransform: { $0 ?? "—" }
      )
      
      MergeFieldPicker(
        label: "Brand",
        value: $mergedItem.brandName,
        options: collectOptions(\.brandName),
        displayTransform: { $0 ?? "—" }
      )
      
      MergeFieldPicker(
        label: "Flavor",
        value: $mergedItem.flavour,
        options: collectOptions(\.flavour),
        displayTransform: { $0 ?? "—" }
      )
      
      MergeFieldPicker(
        label: "Barcode",
        value: $mergedItem.barcode,
        options: collectOptions(\.barcode),
        displayTransform: { $0 ?? "—" }
      )
      
      MergeFieldPicker(
        label: "State",
        value: $mergedItem.state,
        options: collectOptions(\.state),
        displayTransform: { $0.name }
      )
      
      Divider()
      
      Text("Nutritional Information")
        .font(.headline)
      
      MergeFieldPicker(
        label: "Calories",
        value: $mergedItem.calories,
        options: collectOptions(\.calories),
        displayTransform: { $0.map { "\($0)" } ?? "—" }
      )
      
      MergeFieldPicker(
        label: "Protein",
        value: $mergedItem.protein,
        options: collectOptions(\.protein),
        displayTransform: { $0.map { "\($0)g" } ?? "—" }
      )
      
      MergeFieldPicker(
        label: "Carbohydrates",
        value: $mergedItem.carbohydrates,
        options: collectOptions(\.carbohydrates),
        displayTransform: { $0.map { "\($0)g" } ?? "—" }
      )
      
      MergeFieldPicker(
        label: "Fat",
        value: $mergedItem.fat,
        options: collectOptions(\.fat),
        displayTransform: { $0.map { "\($0)g" } ?? "—" }
      )
      
      Divider()
      
      Text("Additional Information")
        .font(.headline)
      
      MergeFieldPicker(
        label: "Ingredients",
        value: $mergedItem.ingredients,
        options: collectOptions(\.ingredients),
        displayTransform: { $0 ?? "—" }
      )
      
      MergeFieldPicker(
        label: "Notes",
        value: $mergedItem.notes,
        options: collectOptions(\.notes),
        displayTransform: { $0 ?? "—" }
      )
    }
  }
  
  private func collectOptions<T: Equatable>(_ keyPath: KeyPath<AdminFoodItemRecord, T>) -> [T] {
    var options: [T] = []
    let allItems = [group.primaryItem] + selectedItems
    
    for item in allItems {
      let value = item[keyPath: keyPath]
      if !options.contains(value) {
        options.append(value)
      }
    }
    
    return options
  }
  
  private func performMerge() async {
    isProcessing = true
    errorMessage = nil
    
    do {
      try await store.mergeFoodItems(
        primaryItem: group.primaryItem,
        itemsToMerge: selectedItems,
        mergedData: mergedItem
      )
      dismiss()
    } catch {
      errorMessage = "Failed to merge items: \(error.localizedDescription)"
    }
    
    isProcessing = false
  }
}

struct MergeFieldPicker<T: Equatable>: View {
  let label: String
  @Binding var value: T
  let options: [T]
  let displayTransform: (T) -> String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      
      if options.count <= 1 {
        Text(displayTransform(value))
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.gray.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 6))
      } else {
        Menu {
          ForEach(options.indices, id: \.self) { index in
            Button {
              value = options[index]
            } label: {
              HStack {
                Text(displayTransform(options[index]))
                if value == options[index] {
                  Spacer()
                  Image(systemName: "checkmark")
                }
              }
            }
          }
        } label: {
          HStack {
            Text(displayTransform(value))
              .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity)
          .background(Color.accentColor.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 6))
        }
      }
    }
  }
}
