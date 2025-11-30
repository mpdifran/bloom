//
//  StorageManagementView.swift
//  Gardener
//
//  Created by Claude Code on 2025-11-30.
//

import AdminBloomModel
import SwiftUI

struct StorageManagementView: View {

  @State private var viewModel = StorageManagementViewModel()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        // Storage Statistics Section
        storageStatsSection

        Divider()

        // Orphaned Images Section
        orphanedImagesSection

        Divider()

        // Large Images Section
        largeImagesSection
      }
      .padding()
    }
    .navigationTitle("Storage Management")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          Task {
            await viewModel.loadStorageStats()
          }
        } label: {
          Image(systemName: "arrow.clockwise")
            .imageScale(.large)
        }
        .disabled(viewModel.isLoadingStats)
      }
    }
    .task {
      await viewModel.loadStorageStats()
    }
  }
}

// MARK: - Storage Stats Section

private extension StorageManagementView {

  var storageStatsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Storage Statistics")
        .font(.title2)
        .bold()

      if viewModel.isLoadingStats {
        ProgressView()
          .padding()
      } else if let error = viewModel.statsError {
        Text(error)
          .foregroundColor(.red)
      } else if let stats = viewModel.storageStats {
        statsGrid(stats: stats)
      }
    }
  }

  func statsGrid(stats: StorageStats) -> some View {
    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
      GridRow {
        Text("Folder")
          .font(.headline)
        Text("Files")
          .font(.headline)
        Text("Size (MB)")
          .font(.headline)
      }

      GridRow {
        Text("Nutrition Labels")
        Text("\(stats.nutritionLabelStats.fileCount)")
        Text(String(format: "%.2f", stats.nutritionLabelStats.totalMB))
      }

      GridRow {
        Text("Food Packaging")
        Text("\(stats.foodPackagingStats.fileCount)")
        Text(String(format: "%.2f", stats.foodPackagingStats.totalMB))
      }

      GridRow {
        Text("Chat Images")
        Text("\(stats.chatImagesStats.fileCount)")
        Text(String(format: "%.2f", stats.chatImagesStats.totalMB))
      }

      GridRow {
        Text("Magic Scanner")
        Text("\(stats.magicScannerStats.fileCount)")
        Text(String(format: "%.2f", stats.magicScannerStats.totalMB))
      }

      GridRow {
        Text("Total")
          .bold()
        Text("\(totalFileCount(stats))")
          .bold()
        Text(String(format: "%.2f", totalSize(stats)))
          .bold()
      }
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(8)
  }

  func totalFileCount(_ stats: StorageStats) -> Int {
    stats.nutritionLabelStats.fileCount +
    stats.foodPackagingStats.fileCount +
    stats.chatImagesStats.fileCount +
    stats.magicScannerStats.fileCount
  }

  func totalSize(_ stats: StorageStats) -> Double {
    stats.nutritionLabelStats.totalMB +
    stats.foodPackagingStats.totalMB +
    stats.chatImagesStats.totalMB +
    stats.magicScannerStats.totalMB
  }
}

// MARK: - Orphaned Images Section

private extension StorageManagementView {

  var orphanedImagesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Orphaned Images")
        .font(.title2)
        .bold()

      Text("Find and delete images in S3 that are not referenced in the database.")
        .font(.subheadline)
        .foregroundColor(.secondary)

      HStack(spacing: 12) {
        AsyncButton {
          await viewModel.findOrphanedImages()
        } label: {
          Text("Find Orphaned Images")
        }
        .disabled(viewModel.isLoadingOrphanedImages)

        if let orphanedInfo = viewModel.orphanedImagesInfo {
          AsyncButton {
            await viewModel.deleteOrphanedImages()
          } label: {
            Text("Delete All (\(orphanedInfo.totalCount))")
          }
          .disabled(viewModel.isDeletingOrphanedImages || orphanedInfo.totalCount == 0)
          .buttonStyle(.borderedProminent)
          .tint(.red)
        }
      }

      if viewModel.isLoadingOrphanedImages {
        ProgressView()
          .padding()
      }

      if let orphanedInfo = viewModel.orphanedImagesInfo {
        VStack(alignment: .leading, spacing: 8) {
          Text("Found \(orphanedInfo.totalCount) orphaned images")
            .font(.headline)
          Text("Total size: \(String(format: "%.2f MB", orphanedInfo.totalMB))")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
      }

      if let error = viewModel.orphanedImagesError {
        Text(error)
          .foregroundColor(.red)
      }

      if let result = viewModel.deleteResult {
        Text(result)
          .foregroundColor(.green)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.green.opacity(0.1))
          .cornerRadius(8)
      }

      if viewModel.isDeletingOrphanedImages {
        ProgressView("Deleting orphaned images...")
          .padding()
      }
    }
  }
}

// MARK: - Large Images Section

private extension StorageManagementView {

  var largeImagesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Large Images")
        .font(.title2)
        .bold()

      Text("Find and resize images larger than a specified threshold.")
        .font(.subheadline)
        .foregroundColor(.secondary)

      HStack(spacing: 12) {
        Text("Size threshold (KB):")
        TextField("Size", value: $viewModel.sizeThresholdKB, format: .number)
          .textFieldStyle(.roundedBorder)
          .frame(width: 100)
          .disabled(viewModel.isLoadingLargeImages)
      }

      HStack(spacing: 12) {
        AsyncButton {
          await viewModel.findLargeImages()
        } label: {
          Text("Find Large Images")
        }
        .disabled(viewModel.isLoadingLargeImages)

        if let largeInfo = viewModel.largeImagesInfo {
          AsyncButton {
            await viewModel.resizeLargeImages()
          } label: {
            Text("Resize All (\(largeInfo.totalCount))")
          }
          .disabled(viewModel.isResizingImages || largeInfo.totalCount == 0)
          .buttonStyle(.borderedProminent)
        }
      }

      if viewModel.isLoadingLargeImages {
        ProgressView()
          .padding()
      }

      if let largeInfo = viewModel.largeImagesInfo {
        VStack(alignment: .leading, spacing: 8) {
          Text("Found \(largeInfo.totalCount) large images")
            .font(.headline)
          Text("Total size: \(String(format: "%.2f MB", largeInfo.totalMB))")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
      }

      if let error = viewModel.largeImagesError {
        Text(error)
          .foregroundColor(.red)
      }

      if viewModel.isResizingImages {
        VStack(alignment: .leading, spacing: 8) {
          ProgressView(value: viewModel.resizeProgress)
          if let status = viewModel.resizeStatus {
            Text(status)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .padding()
      } else if let status = viewModel.resizeStatus {
        Text(status)
          .foregroundColor(.green)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.green.opacity(0.1))
          .cornerRadius(8)
      }
    }
  }
}

#Preview {
  StorageManagementView()
}
