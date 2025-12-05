//
//  SalePreviewView.swift
//  Gardener
//
//  Created by Claude on 2025-12-03.
//

import SwiftUI
import AppKit
import AdminBloomModel

private extension CGFloat {
  static let imageHeight: CGFloat = 250
}

struct SalePreviewView: View {
  @ObservedObject var viewModel: SaleDetailViewModel

  var body: some View {
    VStack(spacing: 0) {
      saleImageView

      VStack(spacing: 12) {
        textContentSection
        discountBadgeSection
        purchaseSection
      }
      .padding()
    }
    .background(.background.secondary)
    .clipShape(RoundedRectangle(cornerRadius: 17))
    .frame(width: 340)
  }
}

private extension SalePreviewView {

  @ViewBuilder
  var saleImageView: some View {
    ZStack {
      Group {
        if let selectedImage = viewModel.selectedImage {
          // Show selected NSImage
          Image(nsImage: selectedImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else if let imageURLString = viewModel.currentImageURL, !imageURLString.isEmpty,
                  let imageURL = URL(string: imageURLString) {
          // Load image from URL
          AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            case .empty:
              // Loading state
              Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                  VStack {
                    ProgressView()
                    Text("Loading...")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
            case .failure(let error):
              // Error state with details
              Rectangle()
                .fill(Color.red.opacity(0.1))
                .overlay {
                  VStack {
                    Image(systemName: "exclamationmark.triangle")
                      .foregroundColor(.red)
                    Text("Failed to load")
                      .font(.caption)
                      .foregroundColor(.secondary)
                    Text(error.localizedDescription)
                      .font(.caption2)
                      .foregroundColor(.secondary)
                      .multilineTextAlignment(.center)
                      .padding(.horizontal)
                  }
                }
            @unknown default:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
            }
          }
        } else {
          // Placeholder
          Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
              Text("No Image")
                .foregroundColor(.secondary)
            }
        }
      }
      .frame(height: .imageHeight)
      .clipped()

      mockDismissButton
        .padding()
        .zStackAlignment(.topLeading)

      timeRemainingBadge
        .padding()
        .zStackAlignment(.topTrailing)
    }
  }

  @ViewBuilder
  var timeRemainingBadge: some View {
    if let timeRemaining = timeRemainingText {
      Text(timeRemaining)
        .font(.subheadline)
        .bold()
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background {
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.red.opacity(0.8))
        }
    }
  }

  @ViewBuilder
  var textContentSection: some View {
    if !viewModel.title.isEmpty {
      Text(viewModel.title)
        .font(.title2)
        .bold()
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    if !viewModel.bodyText.isEmpty {
      Text(viewModel.bodyText)
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  var discountBadgeSection: some View {
    let hasBackgroundColor = !viewModel.discountBadgeBackgroundColor.isEmpty
    let hasForegroundColor = !viewModel.discountBadgeForegroundColor.isEmpty

    if hasBackgroundColor || hasForegroundColor {
      HStack(spacing: 12) {
        Text("50% OFF (example)")
          .font(.body)
          .bold()
          .foregroundColor(parsedForegroundColor)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background {
            RoundedRectangle(cornerRadius: 12)
              .fill(parsedBackgroundColor)
          }
      }
    }
  }

  var mockDismissButton: some View {
    Image(systemName: "xmark")
      .bold()
      .padding(6)
      .background {
        Circle()
          .fill(.regularMaterial)
      }
  }

  @ViewBuilder
  var purchaseSection: some View {
    let buttonTitle = viewModel.purchaseButtonTitle.isEmpty ? "View Offer" : viewModel.purchaseButtonTitle
    let gradientColors = parseGradientColors()

    Button(action: {}) {
      Text(buttonTitle)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    .buttonStyle(GradientButtonStyleMacOS(hexColors: gradientColors))

    if !viewModel.purchaseButtonFooterText.isEmpty {
      Text(viewModel.purchaseButtonFooterText)
        .font(.subheadline)
        .bold()
        .foregroundColor(.secondary)
    }
  }
}

private extension SalePreviewView {

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

  var parsedBackgroundColor: Color {
    if let color = Color(hex: viewModel.discountBadgeBackgroundColor) {
      return color
    }
    return Color.blue.opacity(0.8)
  }

  var parsedForegroundColor: Color {
    if let color = Color(hex: viewModel.discountBadgeForegroundColor) {
      return color
    }
    return Color.white
  }

  func parseGradientColors() -> [String] {
    let colorsString = viewModel.purchaseButtonGradientColors
    if colorsString.isEmpty {
      return ["#007AFF"] // Default blue
    }

    return colorsString
      .components(separatedBy: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }
}

// MARK: - Gradient Button Style

struct GradientButtonStyleMacOS: ButtonStyle {
  let hexColors: [String]

  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
    }
    .bold()
    .padding(.horizontal)
    .background(gradientBackground)
    .foregroundStyle(.invertedText)
    .clipShape(Capsule())
  }

  @ViewBuilder
  private var gradientBackground: some View {
    if hexColors.count == 1 {
      Color(hex: hexColors[0]) ?? Color.blue
    } else {
      LinearGradient(
        gradient: Gradient(colors: hexColors.compactMap { Color(hex: $0) }),
        startPoint: .leading,
        endPoint: .trailing
      )
    }
  }
}

// MARK: - Color Hex Extension

extension Color {
  init?(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))

    guard hex.count == 6 else { return nil }

    var rgb: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&rgb)

    let r = Double((rgb & 0xFF0000) >> 16) / 255.0
    let g = Double((rgb & 0x00FF00) >> 8) / 255.0
    let b = Double(rgb & 0x0000FF) / 255.0

    self.init(red: r, green: g, blue: b)
  }
}

#Preview {
  VStack {
    SalePreviewView(
      viewModel: SaleDetailViewModel(
        sale: .defaultSale,
        store: SalesStore.shared
      )
    )
  }
  .horizontallyCentered()
}
