//
//  StorageAnalysisView.swift
//  Bloom
//
//  Created by Claude on 2025-08-08.
//

import SwiftUI
import AppUI

struct StorageAnalysisView: View {
  @StateObject private var analyzer = StorageAnalyzer()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if analyzer.isAnalyzing {
          VStack(spacing: 20) {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(1.5)

            Text("Analyzing Storage...")
              .font(.headline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if analyzer.categories.isEmpty {
          VStack(spacing: 20) {
            Image(systemSymbol: .chartPie)
              .font(.system(size: 60))
              .foregroundStyle(.secondary)

            Text("Tap Analyze to scan storage usage")
              .font(.headline)
              .foregroundStyle(.secondary)

            Button("Analyze Storage") {
              Task {
                await analyzer.analyzeStorage()
              }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            VStack(spacing: 20) {
              totalStorageHeader

              VStack(spacing: 16) {
                ForEach(analyzer.categories, id: \.name) { category in
                  StorageCategoryRow(category: category, totalStorageSize: analyzer.totalStorageSize)
                }
              }
              .padding()
            }
          }
        }
      }
      .groupedBackground()
      .navigationTitle("Storage Analysis")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }

        if !analyzer.categories.isEmpty {
          ToolbarItem(placement: .primaryAction) {
            Button("Refresh") {
              Task {
                await analyzer.analyzeStorage()
              }
            }
          }
        }
      }
    }
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .task {
      await analyzer.analyzeStorage()
    }
  }

  private var totalStorageHeader: some View {
    VStack(spacing: 8) {
      Text("Total Storage")
        .font(.headline)
        .foregroundStyle(.secondary)

      Text(ByteCountFormatter.string(fromByteCount: analyzer.totalStorageSize, countStyle: .file))
        .font(.largeTitle)
        .fontWeight(.bold)
        .fontDesign(.rounded)
    }
    .padding(.top)
  }
}

struct StorageCategoryRow: View {
  let category: StorageCategory
  let totalStorageSize: Int64

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(category.name)
            .font(.headline)

          if let details = category.details {
            Text(details)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Text(category.sizeFormatted)
            .font(.body)
            .fontWeight(.medium)
            .fontDesign(.rounded)

          Text("\(Int(category.percentage(of: totalStorageSize)))%")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 8)

          RoundedRectangle(cornerRadius: 4)
            .fill(Color.accent)
            .frame(width: geometry.size.width * (category.percentage(of: totalStorageSize) / 100), height: 8)
        }
      }
      .frame(height: 8)
    }
    .padding()
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(12)
  }
}

#Preview {
  PreviewEnvironment {
    StorageAnalysisView()
  }
}
