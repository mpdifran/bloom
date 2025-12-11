//
//  SaleModalView.swift
//  Bloom
//
//  Created by Claude on 2025-12-02.
//

import BloomModel
import RevenueCat
import SwiftUI
import TelemetryDeck

private extension CGFloat {
  static let imageHeight: CGFloat = 300
}

// MARK: - Sale Purchase Error

enum SalePurchaseError: LocalizedError {
  case productNotFound

  var errorDescription: String? {
    switch self {
    case .productNotFound:
      return "Unable to find the product. Please try again later."
    }
  }
}

struct SaleModalView: View {
  let sale: SaleDetails
  let preloadedImage: UIImage?

  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var entitlementController = EntitlementController.shared
  @State private var error: Error?

  var body: some View {
    NavigationStack {
      CardView(cornerRadius: 60) {
        saleImageView

        VStack {
          textContentSection
          discountDetailsSection
          purchaseSection
        }
        .padding(.horizontal)
        .padding(.top)
      }
      .fontDesign(.rounded)
      .ignoresSafeArea(edges: .top)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
    .background {
      Color(.secondarySystemBackground)
        .ignoresSafeArea()
    }
    .task {
      // Log telemetry when sale is shown
      TelemetryDeck.signal("View Sale Modal", parameters: ["sale": sale.telemetryEventName])
      await SalesManager.shared.markSaleAsShown(sale.id)
    }
    .onChange(of: entitlementController.hasBloomPro) { _, hasBloomPro in
      guard hasBloomPro == true else { return }

      TelemetryDeck.signal("Sale Modal Purchase", parameters: ["sale": sale.telemetryEventName])

      dismiss()
    }
    .alert(error: $error)
  }
}

private extension SaleModalView {

  @ViewBuilder
  var saleImageView: some View {
    GeometryReader { proxy in
      Group {
        if let preloadedImage {
          // Use preloaded image for instant display
          Image(uiImage: preloadedImage)
            .resizable()
            .scaledToFill()
        } else if let imageURLString = sale.imageURL,
                  let imageURL = URL(string: imageURLString) {
          // Fallback to AsyncImage if preload failed
          AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .scaledToFill()
            case .empty, .failure:
              Rectangle()
                .fill(.fill)
            @unknown default:
              Rectangle()
                .fill(.fill)
            }
          }
        } else {
          // No URL - show default image
          Image(.budLounging)
            .resizable()
            .scaledToFill()
        }
      }
      .frame(width: proxy.size.width)
      .clipped()
      .overlay {
        timeRemainingBadge
          .padding()
          .padding(.horizontal)
          .zStackAlignment(.topTrailing)
      }
    }
    .frame(height: .imageHeight)
  }

  @ViewBuilder
  var timeRemainingBadge: some View {
    if let timeRemaining = timeRemainingText {
      TimelineView(.everyMinute) { _ in
        Text(timeRemaining)
          .foregroundStyle(.white)
          .font(.subheadline)
          .fontDesign(.rounded)
          .bold()
          .padding(.horizontal, 12)
          .padding(.vertical, 4)
          .background {
            RoundedRectangle(cornerRadius: 10)
              .fill(.mutedRed)
          }
      }
    }
  }

  @ViewBuilder
  var textContentSection: some View {
    Text(sale.title)
      .font(.title)
      .bold()
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)

    Text(sale.bodyText)
      .font(.body)
      .multilineTextAlignment(.center)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
      .padding(.bottom)
  }

  @ViewBuilder
  var discountDetailsSection: some View {
    let hasDiscount = discountPercentage != nil && discountPercentage! > 0
    let hasTrial = trialOfferText != nil

    if hasDiscount || hasTrial {
      HStack(spacing: 12) {
        if let discount = discountPercentage, discount > 0 {
          Text("\(discount)% OFF")
            .padding()
            .background {
              RoundedRectangle(cornerRadius: 17)
                .fill(badgeBackgroundColor)
            }
        }

        if let trialOffer = trialOfferText {
          Text(trialOffer)
            .padding()
            .background {
              RoundedRectangle(cornerRadius: 17)
                .fill(badgeBackgroundColor)
            }
        }
      }
      .font(.title2)
      .minimumScaleFactor(0.6)
      .fontWeight(.heavy)
      .fontWidth(.compressed)
      .fontDesign(.rounded)
      .foregroundStyle(badgeForegroundColor)
      .padding(.bottom)
    }
  }

  @ViewBuilder
  var purchaseSection: some View {
    if let gradientColors = sale.purchaseButtonGradientColors, !gradientColors.isEmpty {
      AsyncButton {
        try await purchaseSaleProduct()
      } label: {
        Text(sale.purchaseButtonTitle ?? "View Offer")
          .horizontallyCentered()
      }
      .buttonStyle(GradientButtonStyle(hexColors: gradientColors))
    } else {
      AsyncButton {
        try await purchaseSaleProduct()
      } label: {
        Text(sale.purchaseButtonTitle ?? "View Offer")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }

    if let footerText = sale.purchaseButtonFooterText {
      Text(footerText)
        .font(.subheadline)
        .bold()
        .foregroundStyle(.secondary)
    }
  }
}

private extension SaleModalView {

  var discountPercentage: Int? {
    // Get packages from EntitlementController
    guard let salePackage = EntitlementController.shared.package(for: sale.saleProductId) else {
      return nil
    }

    guard let compareProductId = sale.compareProductId,
          let comparePackage = EntitlementController.shared.package(for: compareProductId) else {
      return nil
    }

    // Calculate percentage discount
    let salePrice = (salePackage.storeProduct.price as NSDecimalNumber).doubleValue
    let comparePrice = (comparePackage.storeProduct.price as NSDecimalNumber).doubleValue

    guard comparePrice > salePrice else { return nil }

    let discount = ((comparePrice - salePrice) / comparePrice) * 100

    // Round to nearest 1%
    return Int(discount.rounded())
  }

  var trialOfferText: String? {
    guard let salePackage = EntitlementController.shared.package(for: sale.saleProductId) else {
      return nil
    }

    // Use the same helper method as the paywall
    return salePackage.introductoryOfferTrialString
  }

  var timeRemainingText: String? {
    let now = Date()
    let endDate = sale.endDate

    // Don't show if sale has ended
    guard endDate > now else { return nil }

    let timeInterval = endDate.timeIntervalSince(now)
    let hours = Int(timeInterval / 3600)
    let days = hours / 24

    // Show days if 1 or more days remaining
    if days >= 1 {
      return "\(days) Day\(days == 1 ? "" : "s") Left"
    }

    // Show hours if less than 1 day but more than 0 hours
    if hours >= 1 {
      return "\(hours) Hour\(hours == 1 ? "" : "s") Left"
    }

    // Show "Less than 1 hour" for final hour
    return "Less Than 1 Hour Left"
  }

  var badgeBackgroundColor: Color {
    if let hexColor = sale.discountBadgeBackgroundColor {
      return Color(hex: hexColor) ?? .mutedBlue
    }
    return .mutedBlue
  }

  var badgeForegroundColor: Color {
    if let hexColor = sale.discountBadgeForegroundColor {
      return Color(hex: hexColor) ?? .white
    }
    return .white
  }

  func purchaseSaleProduct() async throws {
    guard let package = EntitlementController.shared.package(for: sale.saleProductId) else {
      throw SalePurchaseError.productNotFound
    }

    TelemetryDeck.signal("Sale Modal Attempt Purchase", parameters: ["sale": sale.telemetryEventName])

    _ = try await Purchases.shared.purchase(package: package)
  }
}

// MARK: - Gradient Button Style

private struct GradientButtonStyle: ButtonStyle {
  let hexColors: [String]

  func makeBody(configuration: ButtonStyle.Configuration) -> some View {
    if #available(iOS 26.0, *) {
      HStack {
        configuration.label
      }
      .bold()
      .padding(.vertical, 16)
      .padding(.horizontal)
      .background(gradientBackground)
      .foregroundStyle(.white)
      .clipShape(Capsule())
    } else {
      HStack {
        configuration.label
      }
      .bold()
      .padding(.vertical, 16)
      .padding(.horizontal)
      .background(gradientBackground)
      .foregroundStyle(.white)
      .clipShape(RoundedRectangle(cornerRadius: 17))
    }
  }

  @ViewBuilder
  private var gradientBackground: some View {
    if hexColors.count == 1 {
      // Single color
      Color(hex: hexColors[0])
    } else {
      // Gradient with multiple colors
      LinearGradient(
        gradient: Gradient(colors: hexColors.compactMap { Color(hex: $0) }),
        startPoint: .leading,
        endPoint: .trailing
      )
    }
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      SaleModalView(
        sale: SaleDetails(
          id: "sale_123",
          title: "New Year, New You!",
          bodyText: "Get a jump on the new year with the best deal you'll see on Bloom! Your rate is locked in indefinitely.",
          imageURL: "https://lotus-labs-bloom-default.s3.us-east-1.amazonaws.com/sale-images/1C133E72-8B03-487C-998C-D3CBC1ACD28D.png",
          saleProductId: "bloom_2999_1y_7d0",
          compareProductId: "bloom_pro_yearly",
          targetAudiences: [.freeUsers, .expiredUsers],
          startDate: .now,
          endDate: Date().addingTimeInterval(86400),
          displayFrequencyDays: 3,
          isActive: true,
          telemetryEventName: "preview_sale",
          purchaseButtonTitle: "Upgrade",
          purchaseButtonGradientColors: ["#5BBDE1", "#3798C8", "#3EC17D"],
          purchaseButtonFooterText: "Share with up to 5 family members",
          discountBadgeBackgroundColor: nil,
          discountBadgeForegroundColor: nil,
          createdAt: .now,
          updatedAt: .now
        ),
        preloadedImage: nil
      )
    }
  }
}
