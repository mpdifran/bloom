//
//  ActionInstanceCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import SwiftUI
import SFSafeSymbols

struct ActionInstanceCell: View {
  private let image: ImageResource?
  private let systemSymbol: SFSymbol?
  let title: String

  init(image: ImageResource, title: String) {
    self.image = image
    self.systemSymbol = nil
    self.title = title
  }

  init(systemSymbol: SFSymbol, title: String) {
    self.image = nil
    self.systemSymbol = systemSymbol
    self.title = title
  }

  var body: some View {
    HStack(spacing: 16) {
      icon
        .frame(width: 28, height: 28)

      Text(title)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      DisclosureIndicator()
    }
    .foregroundStyle(.white)
    .cardContainer(fill: .tint)
  }

  @ViewBuilder
  private var icon: some View {
    if let image {
      Image(image)
    } else if let systemSymbol {
      Image(systemSymbol: systemSymbol)
        .font(.system(size: 20, weight: .semibold))
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ActionInstanceCell(image: .todayTab, title: "Weight")
        .tint(.mutedPurple)
    }
  }
}
