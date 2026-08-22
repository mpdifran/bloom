//
//  OnboardingTitleCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SFSafeSymbols
import SwiftUI

struct OnboardingTitleCardView: View {
  let symbol: SFSymbol
  let title: LocalizedStringKey
  let message: LocalizedStringKey

  init(
    symbol: SFSymbol = .handRaisedCircleFill,
    title: LocalizedStringKey,
    message: LocalizedStringKey
  ) {
    self.symbol = symbol
    self.title = title
    self.message = message
  }

  var body: some View {
    VStack(spacing: 15) {
      Image(systemSymbol: symbol)
        .foregroundStyle(.white, .tint)
        .font(.system(size: 80))
      Text(title)
        .font(.largeTitle)
        .bold()
      Text(message)
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }
}

#Preview {
  OnboardingTitleCardView(
    title: "Age & Sex",
    message: "This is a message about health data."
  )
}
