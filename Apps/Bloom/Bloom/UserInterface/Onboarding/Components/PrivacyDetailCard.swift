//
//  PrivacyDetailCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-21.
//

import SwiftUI
import SFSafeSymbols

struct PrivacyDetailCard: View {
  let symbol: SFSymbol
  let title: LocalizedStringKey
  let detail: LocalizedStringKey

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemSymbol: symbol)
          .font(.title3)
          .foregroundStyle(.white)
          .frame(square: 30)
          .padding(6)
          .background {
            RoundedRectangle(cornerRadius: 13)
              .fill(.tint)
          }

        Text(title)
          .font(.title3)
          .fontDesign(.rounded)
          .bold()
      }

      Text(detail)
        .font(.body)
        .fontDesign(.rounded)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      PrivacyDetailCard(
        symbol: .handRaisedFill,
        title: "Data Retention",
        detail: "We only keep your data for as long as needed to create your insights, then it’s cleared automatically."
      )
    }
  }
}
