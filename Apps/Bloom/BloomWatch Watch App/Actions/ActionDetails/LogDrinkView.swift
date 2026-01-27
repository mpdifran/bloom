//
//  LogDrinkView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import SwiftUI
import CoreHealth
import BloomFoundation

struct LogDrinkView: View {
  let performDismiss: (() -> Void)?

  @State private var navigationPath = NavigationPath()

  var body: some View {
    NavigationStack(path: $navigationPath) {
      List {
        ForEach(DrinkType.defaultDrinks) { drink in
          DrinkCell(drink: drink)
            .onTapGesture {
              handleDrinkTapped(drink)
            }
        }
      }
      .listStyle(.carousel)
      .navigationTitle("Log Drink")
      .navigationDestination(for: DrinkNavigation.self) { destination in
        switch destination {
        case .subTypes(let parentDrink):
          DrinkSubTypeListView(
            parentDrink: parentDrink,
            navigationPath: $navigationPath,
            performDismiss: performDismiss
          )

        case .container(let drink):
          ContainerListView(
            drink: drink,
            performDismiss: performDismiss
          )
        }
      }
    }
  }

  private func handleDrinkTapped(_ drink: DrinkType) {
    if drink.hasSubTypes {
      navigationPath.append(DrinkNavigation.subTypes(drink))
    } else {
      navigationPath.append(DrinkNavigation.container(drink))
    }
  }
}

// MARK: - Navigation

enum DrinkNavigation: Hashable {
  case subTypes(DrinkType)
  case container(DrinkType)
}

// MARK: - Drink Cell

private struct DrinkCell: View {
  let drink: DrinkType

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

        if drink.hasSubTypes {
          Text("Tap to choose type")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      if drink.hasSubTypes {
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  PreviewEnvironment {
    LogDrinkView(performDismiss: nil)
  }
}
