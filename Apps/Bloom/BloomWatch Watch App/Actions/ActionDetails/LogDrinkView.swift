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
    .frame(maxWidth: .infinity)
    .background(.black)
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

#Preview {
  PreviewEnvironment {
    LogDrinkView(performDismiss: nil)
  }
}
