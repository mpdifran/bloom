//
//  SaleDetailsCellPreview.swift
//  Gardener
//
//  Created by Claude on 2025-12-11.
//

import SwiftUI
import AppKit
import AdminBloomModel

private extension CGFloat {
  static let imageWidth: CGFloat = 130
}

struct SaleDetailsCellPreview: View {
  @ObservedObject var viewModel: SaleDetailViewModel

  var body: some View {
    HStack(spacing: 0) {
      saleImageView

      VStack(alignment: .leading) {
        saleDescriptionView
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
    }
    .background(.background.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 17))
    .frame(width: 340)
  }
}

private extension SaleDetailsCellPreview {

  @ViewBuilder
  var saleImageView: some View {
    ZStack {
      Group {
        if let selectedImage = viewModel.selectedImage {
          Image(nsImage: selectedImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else if let imageURLString = viewModel.currentImageURL, !imageURLString.isEmpty,
                  let imageURL = URL(string: imageURLString) {
          AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            case .empty:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                  ProgressView()
                }
            case .failure:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
            @unknown default:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
            }
          }
        } else {
          Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
              Text("No Image")
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
      }
      .frame(width: .imageWidth)
      .clipped()

      timeRemainingBadge
        .padding(8)
        .zStackAlignment(.bottom)
    }
  }

  @ViewBuilder
  var timeRemainingBadge: some View {
    if let timeRemaining = timeRemainingText {
      Text(timeRemaining)
        .font(.caption)
        .bold()
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background {
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.red.opacity(0.8))
        }
    }
  }

  @ViewBuilder
  var saleDescriptionView: some View {
    HStack {
      Text(viewModel.title.isEmpty ? "Sale Title" : viewModel.title)
      Spacer()
      Image(systemName: "chevron.forward")
        .font(.subheadline)
    }
    .font(.headline)
    .bold()
    .multilineTextAlignment(.leading)
    .fixedSize(horizontal: false, vertical: true)

    Text(viewModel.bodyText.isEmpty ? "Sale description text" : viewModel.bodyText)
      .font(.subheadline)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
  }

  var timeRemainingText: String? {
    let startDate = viewModel.startDate
    let endDate = viewModel.endDate

    guard endDate > startDate else { return nil }

    let timeInterval = endDate.timeIntervalSince(startDate)
    let hours = Int(timeInterval / 3600)
    let days = hours / 24

    if days >= 1 {
      return "\(days) Day\(days == 1 ? "" : "s") Left"
    }

    if hours >= 1 {
      return "\(hours) Hour\(hours == 1 ? "" : "s") Left"
    }

    return "Less Than 1 Hour Left"
  }
}

#Preview {
  VStack {
    SaleDetailsCellPreview(
      viewModel: SaleDetailViewModel(
        sale: .defaultSale,
        store: SalesStore.shared
      )
    )
  }
  .padding()
}
