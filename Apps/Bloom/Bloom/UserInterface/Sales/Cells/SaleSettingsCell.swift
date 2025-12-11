//
//  SaleSettingsCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-11.
//

import SwiftUI
import BloomModel
import AppUI
import SFSafeSymbols
import TelemetryDeck

private extension CGFloat {
  static let imageHeight: CGFloat = 150
}

struct SaleSettingsCell: View {
  let sale: SaleDetails
  let preloadedImage: UIImage?

  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack(spacing: 0) {
      saleImageView
      VStack(alignment: .leading) {
        saleDescriptionView
      }
      .horizontalAlignment(.leading)
      .padding()
    }
    .cardContainer(includePadding: false)
    .sheet($presentedSheet)
    .onTapGesture {
      TelemetryDeck.signal("Tap Sale Settings Cell", parameters: ["sale": sale.telemetryEventName])
      presentedSheet = SaleModalView(sale: sale, preloadedImage: preloadedImage).asAny
    }
    .onAppear {
      TelemetryDeck.signal("View Sale Settings Cell", parameters: ["sale": sale.telemetryEventName])
    }
  }
}

private extension SaleSettingsCell {

  @ViewBuilder
  var saleImageView: some View {
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
    .frame(height: .imageHeight)
    .clipped()
    .overlay {
      timeRemainingBadge
        .padding()
        .zStackAlignment(.topTrailing)
    }
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
  var discountDetailsSection: some View {
    let hasDiscount = discountPercentage != nil && discountPercentage! > 0
    let hasTrial = trialOfferText != nil

    if hasDiscount || hasTrial {
      HStack(spacing: 12) {
        if let discount = discountPercentage, discount > 0 {
          Text("\(discount)% OFF")
            .padding(.vertical, 4)
            .padding(.horizontal)
            .background {
              Capsule()
                .fill(badgeBackgroundColor)
            }
        }

        if let trialOffer = trialOfferText {
          Text(trialOffer)
            .padding(.vertical, 4)
            .padding(.horizontal)
            .background {
              Capsule()
                .fill(badgeBackgroundColor)
            }
        }
      }
      .font(.subheadline)
      .minimumScaleFactor(0.8)
      .fontWeight(.bold)
      .fontWidth(.compressed)
      .fontDesign(.rounded)
      .foregroundStyle(badgeForegroundColor)
    }
  }

  @ViewBuilder
  var saleDescriptionView: some View {
    HStack {
      Text(sale.title)
      Spacer()
      Image(systemSymbol: .chevronForward)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .font(.headline)
    .bold()
    .multilineTextAlignment(.leading)
    .fixedSize(horizontal: false, vertical: true)

    Text(sale.bodyText)
      .font(.subheadline)
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
  }

  var dismissButton: some View {
    Button {

    } label: {
      Circle()
        .fill(.regularMaterial)
        .frame(square: 40)
        .overlay {
          Image(systemSymbol: .xmark)
            .bold()
        }
    }
    .buttonStyle(.plain)
  }
}

private extension SaleSettingsCell {

  var discountPercentage: Int? {
    return 50
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
    return "7 Days Free"
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
}

#Preview {
  PreviewEnvironment {
    BloomScrollView(showsChatBar: false) {
      SaleSettingsCell(
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
