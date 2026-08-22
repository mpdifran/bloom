//
//  DrinkSubTypeListView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import SwiftUI
import CoreHealth
import BloomFoundation

struct DrinkSubTypeListView: View {
  let parentDrink: DrinkType
  @Binding var navigationPath: NavigationPath
  let performDismiss: (() -> Void)?

  var body: some View {
    List {
      if let subTypes = parentDrink.subTypes {
        ForEach(subTypes) { subType in
          SubTypeCell(drink: subType, parentColor: parentDrink.liquidColor)
            .onTapGesture {
              navigationPath.append(DrinkNavigation.container(subType))
            }
        }
      }
    }
    .listStyle(.carousel)
    .navigationTitle(parentDrink.name)
  }
}

// MARK: - Sub Type Cell

private struct SubTypeCell: View {
  let drink: DrinkType
  let parentColor: Color

  var body: some View {
    HStack(spacing: 12) {
      ZStack {
        Circle()
          .fill(drink.liquidColor.opacity(0.2))

        Image(systemName: drink.symbolName)
          .font(.title3)
          .foregroundStyle(drink.liquidColor)
      }
      .frame(width: 44, height: 44)

      VStack(alignment: .leading, spacing: 2) {
        Text(drink.name)
          .font(.headline)
          .fontDesign(.rounded)

        if let abv = drink.abv {
          Text("\(Int(abv))% ABV")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      DrinkSubTypeListView(
        parentDrink: DrinkType.beer,
        navigationPath: .constant(NavigationPath()),
        performDismiss: nil
      )
    }
  }
}
