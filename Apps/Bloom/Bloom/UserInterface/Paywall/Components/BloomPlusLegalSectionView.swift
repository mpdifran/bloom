//
//  BloomPlusLegalSectionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SwiftUI
import AppUI
import TelemetryDeck

struct BloomPlusLegalSectionView: View {
  let restorePurchases: () -> Void

  @State private var showOfferCodeSheet = false
  @State private var error: Error?

  @Environment(\.openURL) private var openURL

  var body: some View {
    VStack {
      Button {
        showOfferCodeSheet.toggle()
      } label: {
        LabeledContent("Promo Code") {
          Image(systemName: "rectangle.and.pencil.and.ellipsis")
            .foregroundStyle(.gray)
        }
        .cardContainer(fill: .background)
      }
      .offerCodeRedemption(isPresented: $showOfferCodeSheet) { result in
          switch result {
          case .failure(let error):
              TelemetryDeck.errorOccurred(
                  id: "PreferencesView.offerCodeRedemption",
                  category: .thrownException,
                  message: error.localizedDescription
              )
              self.error = error
          default:
              break
          }
      }

      Button {
        restorePurchases()
      } label: {
        LabeledContent("Restore Purchase") {
          Image(systemName: "arrow.clockwise")
            .foregroundStyle(.gray)
        }
        .cardContainer(fill: .background)
      }

      Button {
        openURL(.privacyPolicy)
      } label: {
        LabeledContent("Privacy Policy") {
          Image(systemName: "hand.raised.fill")
            .foregroundStyle(.gray)
        }
        .cardContainer(fill: .background)
      }

      Button {
        openURL(.termsOfService)
      } label: {
        LabeledContent("Terms of Service") {
          Image(systemName: "list.clipboard.fill")
            .foregroundStyle(.gray)
        }
        .cardContainer(fill: .background)
      }
    }
    .buttonStyle(.plain)
    .bold()
    .alert(error: $error)
  }
}

#Preview {
  BloomPlusLegalSectionView {
    
  }
  .padding()
}
