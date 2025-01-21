//
//  BloomPlusPackageCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-20.
//

import SwiftUI

struct BloomPlusPackageCell: View {
  let title: String
  let cost: String
  let costMonthly: String?
  let offer: String?
  let isSelected: Bool

  var body: some View {
    HStack {
      CompletionCheckmarkView(
        state: isSelected ? .metGoal : .unmetGoal,
        colorize: isSelected
      )

      VStack(alignment: .leading) {
        Text(title)
          .font(.body)
          .fontDesign(.rounded)
          .bold()

        if let costMonthly {
          Text(costMonthly)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Text(cost)
        .bold()
        .fontDesign(.rounded)
        .font(.headline)
    }
    .cardContainer(fill: .background.secondary)
    .selectable()
    .overlay {
      if let offer {
        Text(offer.uppercased())
          .foregroundStyle(.white)
          .font(.caption)
          .fontDesign(.rounded)
          .bold()
          .padding(.vertical, 2)
          .padding(.horizontal, 8)
          .background {
            Capsule()
              .fill(.tint)
          }
          .zStackAlignment(.topLeading)
          .padding(.leading)
          .offset(y: -10)
      }
    }
  }
}

#Preview {
  VStack {
    Spacer()
    BloomPlusPackageCell(
      title: "Yearly",
      cost: "$39.99",
      costMonthly: "$3.99/month",
      offer: "2 weeks free",
      isSelected: true
    )
    BloomPlusPackageCell(
      title: "Monthly",
      cost: "$9.99",
      costMonthly: nil,
      offer: nil,
      isSelected: false
    )
    Spacer()
  }
  .padding()
  .groupedBackground()
  .tint(.mutedPurple)
}
