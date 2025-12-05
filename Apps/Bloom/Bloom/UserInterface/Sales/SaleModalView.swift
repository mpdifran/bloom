//
//  SaleModalView.swift
//  Bloom
//
//  Created by Claude on 2025-12-02.
//

import BloomModel
import SwiftUI
import TelemetryDeck

private extension CGFloat {
  static let imageHeight: CGFloat = 250
}

struct SaleModalView: View {
  let sale: SaleDetails

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      CardView {
        saleImageView

        VStack {
          textContentSection
          discountDetailsSection
          purchaseSection
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, -40)
      }
      .fontDesign(.rounded)
      .ignoresSafeArea(edges: .top)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
    .task {
      // Log telemetry when sale is shown
      TelemetryDeck.signal(sale.telemetryEventName)
    }
  }
}

private extension SaleModalView {

  @ViewBuilder
  var saleImageView: some View {
    Group {
      if let imageURLString = sale.imageURL,
         let imageURL = URL(string: imageURLString) {
        // Load image from S3 URL
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
      .font(.body)
      .minimumScaleFactor(0.8)
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
        // TODO: Open paywall with sale.saleProductId
        dismiss()
      } label: {
        Text(sale.purchaseButtonTitle ?? "View Offer")
          .horizontallyCentered()
      }
      .buttonStyle(GradientButtonStyle(hexColors: gradientColors))
    } else {
      AsyncButton {
        // TODO: Open paywall with sale.saleProductId
        dismiss()
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
    let salePrice = salePackage.storeProduct.price
    let comparePrice = comparePackage.storeProduct.price

    guard comparePrice > salePrice else { return nil }

    let discount = ((comparePrice - salePrice) / comparePrice) * 100
    let discountInt = Int(truncating: discount as NSDecimalNumber)

    // Round DOWN to nearest 5% (don't over-promise)
    return (discountInt / 5) * 5
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
}

// MARK: - Gradient Button Style

private struct GradientButtonStyle: ButtonStyle {
  let hexColors: [String]

  func makeBody(configuration: Configuration) -> some View {
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
          imageURL: nil,
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
        )
      )
    }
  }
}
