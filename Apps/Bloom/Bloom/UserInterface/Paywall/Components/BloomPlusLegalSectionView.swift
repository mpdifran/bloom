//
//  BloomPlusLegalSectionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SFSafeSymbols
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
        Label("Promo Code", systemSymbol: .tag)
      }
      .frame(minHeight: 44)
      .offerCodeRedemption(isPresented: $showOfferCodeSheet) { result in
          switch result {
          case .failure(let error):
              TelemetryDeck.errorOccurred(
                  id: "BloomPlusLegalSectionView.offerCodeRedemption",
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
        Label("Restore Purchase", systemSymbol: .arrowClockwise)
      }
      .frame(minHeight: 44)

      HStack {
        Spacer(minLength: 0)

        Button("Privacy Policy") {
          openURL(.privacyPolicy)
        }
        .frame(minHeight: 44)

        Text("•")
          .foregroundStyle(.tint)

        Button("Terms of Service") {
          openURL(.termsOfService)
        }
        .frame(minHeight: 44)

        Spacer(minLength: 0)
      }
    }
    .bold()
    .alert(error: $error)
  }
}

#Preview {
  BloomPlusLegalSectionView {
    
  }
  .padding()
}
