//
//  IssueReportComparisonRow.swift
//  Gardener
//
//  Created by Claude on 2025-12-22.
//

import SwiftUI

struct IssueReportComparisonRow: View {
  let label: String
  let currentValue: String
  let suggestedValue: String
  @Binding var isSelected: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Toggle(isOn: $isSelected) {
          Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .toggleStyle(.checkbox)
      }

      HStack(spacing: 16) {
        // Current value (red tint)
        VStack(alignment: .leading, spacing: 4) {
          Text("Current")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text(currentValue)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }

        Image(systemName: "arrow.right")
          .foregroundStyle(.secondary)

        // Suggested value (green tint)
        VStack(alignment: .leading, spacing: 4) {
          Text("Suggested")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text(suggestedValue)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
      }
    }
  }
}

struct IssueReportImageComparisonRow: View {
  let label: String
  let currentImageURL: URL?
  let suggestedImageURL: URL?
  @Binding var isSelected: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Toggle(isOn: $isSelected) {
          Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .toggleStyle(.checkbox)
      }

      HStack(spacing: 16) {
        // Current image
        VStack(alignment: .leading, spacing: 4) {
          Text("Current")
            .font(.caption2)
            .foregroundStyle(.secondary)
          imageView(for: currentImageURL)
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }

        Image(systemName: "arrow.right")
          .foregroundStyle(.secondary)

        // Suggested image
        VStack(alignment: .leading, spacing: 4) {
          Text("Suggested")
            .font(.caption2)
            .foregroundStyle(.secondary)
          imageView(for: suggestedImageURL)
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
      }
    }
  }

  @ViewBuilder
  private func imageView(for url: URL?) -> some View {
    if let url {
      AsyncImage(url: url) { phase in
        switch phase {
        case .empty:
          ProgressView()
        case .success(let image):
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
        case .failure:
          Image(systemName: "exclamationmark.triangle")
            .foregroundStyle(.secondary)
        @unknown default:
          EmptyView()
        }
      }
    } else {
      Text("No image")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}
