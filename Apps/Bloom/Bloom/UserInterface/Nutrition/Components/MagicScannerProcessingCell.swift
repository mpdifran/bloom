//
//  MagicScannerProcessingCell.swift
//  Bloom
//
//  Created by Claude on 2025-10-25.
//

import SwiftUI
import SFSafeSymbols
import DataContainer
import AppUI

struct MagicScannerProcessingCell: View {
  let foodItemLog: FoodItemLog
  let onRetry: () async throws -> Void

  var body: some View {
    HStack(spacing: 0) {
      // Image (always shown if available)
      if let image = foodItemLog.image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(square: 80)
          .clipShape(RoundedRectangle(cornerRadius: 18))
          .padding(.vertical, 8)
          .padding(.leading, 8)
      } else {
        RoundedRectangle(cornerRadius: 18)
          .fill(.background.secondary)
          .frame(square: 80)
          .padding(.vertical, 8)
          .padding(.leading, 8)
      }

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          if let processingState = foodItemLog.processingState {
            switch processingState {
            case .pending, .processing:
              processingView
            case .failed:
              errorView
            case .completed:
              EmptyView() // Shouldn't happen
            }
          }
        }
        .multilineTextAlignment(.leading)

        Spacer()

        // Status icon on right
        if let processingState = foodItemLog.processingState {
          switch processingState {
          case .pending, .processing:
            EmptyView()
          case .failed:
            errorIcon
          case .completed:
            EmptyView()
          }
        }
      }
      .padding()
    }
    .cardContainer(includePadding: false)
  }

  private var processingView: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Analyzing...")
        .font(.body)
        .fontDesign(.rounded)
        .bold()

      if let contextText = foodItemLog.contextText {
        Text(contextText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .shimmer()
  }

  private var errorView: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Oops!")
        .font(.body)
        .fontDesign(.rounded)
        .bold()
        .foregroundStyle(.mutedRed)

      if let errorMessage = foodItemLog.errorMessage {
        Text(errorMessage)
          .font(.caption)
          .foregroundStyle(.mutedRed)
      }
    }
  }

  private var errorIcon: some View {
    AsyncButton {
      try await onRetry()
    } label: {
      Circle()
        .fill(Color.mutedRed.tertiary)
        .frame(square: 40)
        .overlay {
          Image(systemSymbol: .arrowCounterclockwise)
            .font(.title3)
            .foregroundStyle(.mutedRed)
        }
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      // Processing state example
      MagicScannerProcessingCell(
        foodItemLog: {
          let log = FoodItemLog(
            id: UUID().uuidString,
            name: nil,
            date: Date(),
            meal: .lunch,
            numberOfServings: 1,
            imageData: nil,
            foodItemServings: []
          )
          log.processingState = .processing
          log.processingIdentifier = "test_123"
          log.contextText = "Made with butter"
          return log
        }(),
        onRetry: {
          print("Retry tapped")
        }
      )

      // Error state example
      MagicScannerProcessingCell(
        foodItemLog: {
          let log = FoodItemLog(
            id: UUID().uuidString,
            name: nil,
            date: Date(),
            meal: .lunch,
            numberOfServings: 1,
            imageData: nil,
            foodItemServings: []
          )
          log.processingState = .failed
          log.errorMessage = "Failed to process image"
          return log
        }(),
        onRetry: {
          print("Retry tapped")
        }
      )
    }
  }
}
