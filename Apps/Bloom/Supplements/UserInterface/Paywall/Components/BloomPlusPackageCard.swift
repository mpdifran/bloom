//
//  BloomPlusPackageCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-14.
//

import SwiftUI
import AppUI
import RevenueCat

struct BloomPlusPackageCard: View {
  let title: String
  let subtitle: String
  let introOffer: String?
  let isSelected: Bool

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(title)
          .bold()
          .fontDesign(.rounded)
        Text(subtitle)
          .font(.caption)
      }

      Spacer()

      CompletionCheckmarkView(
        state: isSelected ? .metGoal : .unmetGoal,
        colorize: isSelected
      )
    }
    .cardContainer(
      fill: .background.secondary,
      stroke: isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear)
    )
    .overlay(alignment: .top) {
      if let introOffer {
        Text(introOffer.uppercased())
          .foregroundStyle(.white)
          .fontDesign(.rounded)
          .bold()
          .font(.caption)
          .padding(.vertical, 2)
          .padding(.horizontal, 8)
          .background {
            Capsule()
              .fill(.tint)
          }
          .offset(y: -7)
      }
    }
    .selectable()
    .tint(.mutedBlue)
  }
}

#Preview {
  VStack {
    Spacer()
    HStack {
      BloomPlusPackageCard(
        title: "Monthly",
        subtitle: "$9.99 / month",
        introOffer: nil,
        isSelected: true
      )
      BloomPlusPackageCard(
        title: "Yearly",
        subtitle: "$39.99 / year",
        introOffer: "1 month free",
        isSelected: false
      )
    }
    .padding()
    Spacer()
  }
  .horizontallyCentered()
}
