//
//  TestFlightThankYouView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-26.
//

import SwiftUI
import BloomUI

struct TestFlightThankYouView: View {

  @Environment(\.openURL) private var openURL

  var body: some View {
    BloomScrollView(padding: .bottom) {
      ZStack {
        Image(.budLounging)
          .resizable()
          .scaledToFit()
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack {
          appIconSection
          thankYouSection
        }
        .padding(.horizontal)
        .padding(.top, 300)
      }
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .shelf {
      shelfContent
    }
  }
}

private extension TestFlightThankYouView {

  var appIconSection: some View {
    HStack {
      DisplayAppIcon()
        .frame(square: 130)
        .rotationEffect(.degrees(-5))

      DisplayAppIcon(overrideAppIcon: .testFlight)
        .frame(square: 130)
        .rotationEffect(.degrees(5))
    }
  }

  var thankYouSection: some View {
    VStack(alignment: .leading) {
      Text("Thank You!")
        .primaryOnboardingTextStyle()

      Text("Thank you so much for help testing Bloom! We're ending our TestFlight program, so you'll need to install the App Store version of the app to continue using Bloom.")
        .fixedSize(horizontal: false, vertical: true)
        .secondaryOnboardingTextStyle()
        .foregroundStyle(.secondary)
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }

  var shelfContent: some View {
    VStack {
      Text("Loyalty Offer")
        .font(.body)
        .fontDesign(.rounded)
        .bold()

      Text("75% OFF")
        .font(.system(size: 50))
        .fontDesign(.rounded)
        .fontWeight(.black)
        .foregroundStyle(
          LinearGradient(
            colors: [.mutedIndigo, .mutedPink, .mutedRed],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
          )
        )

      Text("Bloom Plus Yearly")
        .font(.caption)
        .fontDesign(.rounded)
        .bold()

      HStack {
        Button {
          openURL(.testFlightPromoAppStoreListing)
        } label: {
          Text("App Store")
            .horizontallyCentered()
        }
        .buttonStyle(.primaryAlternate)

        Button {
          openURL(.testFlightPromo)
        } label: {
          Text("Claim Promo")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    TestFlightThankYouView()
  }
}
