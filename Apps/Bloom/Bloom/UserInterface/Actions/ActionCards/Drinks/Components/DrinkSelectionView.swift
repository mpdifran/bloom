//
//  DrinkSelectionView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import BloomUI

struct DrinkSelectionView: View {

  let performDismiss: (() -> Void)?

  // MARK: - State

  @State private var presentedSheet: SheetType?

  // MARK: - Types

  enum SheetType: Identifiable {
    case selectSubType(DrinkType)
    case selectContainer(DrinkType)

    var id: String {
      switch self {
      case .selectSubType(let drink): "selectSubType-\(drink.id)"
      case .selectContainer(let drink): "selectContainer-\(drink.id)"
      }
    }
  }

  // MARK: - Body

  var body: some View {
    CardView {
      LargeTitleActionCard("Choose a drink") {
        drinkGrid
      }
    }
    .tint(.mutedBlue)
    .sheet(item: $presentedSheet) { sheet in
      sheetContent(for: sheet)
    }
  }

  // MARK: - Drink Grid

  private var drinkGrid: some View {
    ScrollView {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)],
        spacing: 12
      ) {
        ForEach(DrinkType.defaultDrinks) { drink in
          DrinkTypeCell(drink: drink)
            .onTapGesture {
              handleDrinkSelected(drink)
            }
        }
      }
      .padding()
    }
  }

  // MARK: - Navigation

  private func handleDrinkSelected(_ drink: DrinkType) {
    if drink.hasSubTypes {
      presentedSheet = .selectSubType(drink)
    } else {
      presentedSheet = .selectContainer(drink)
    }
  }

  private func handleSubTypeSelected(_ subType: DrinkType) {
    presentedSheet = .selectContainer(subType)
  }

  // MARK: - Sheets

  @ViewBuilder
  private func sheetContent(for sheet: SheetType) -> some View {
    switch sheet {
    case .selectSubType(let parentDrink):
      NavigationStack {
        DrinkSubTypeSelectionView(
          parentDrink: parentDrink,
          onSubTypeSelected: { subType in
            handleSubTypeSelected(subType)
          }
        )
        .navigationTitle("Choose \(parentDrink.name.lowercased()) type")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            DismissButton()
          }
        }
      }
      .presentationDetents([.medium, .large])
      .presentationDragIndicator(.visible)

    case .selectContainer(let drink):
      ContainerSelectionView(
        drink: drink,
        performDismiss: performDismiss
      )
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      DrinkSelectionView(performDismiss: nil)
    }
  }
}
