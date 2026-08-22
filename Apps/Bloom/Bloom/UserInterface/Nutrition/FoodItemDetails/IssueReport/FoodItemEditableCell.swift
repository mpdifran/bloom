//
//  FoodItemEditableCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

import SFSafeSymbols
import SwiftUI

enum FoodItemEditableCellMode {
  case value
  case modifiedValue
}
enum FoodItemEditableCellResetMode {
  case clearValue
  case resetValue
}

struct FoodItemEditableCell<Content>: View where Content: View {
  /// LocalizedStringKey, not String: a String literal is passed straight to Text without a
  /// catalog lookup, so every title rendered in English regardless of language.
  let title: LocalizedStringKey
  let mode: FoodItemEditableCellMode
  let isVertical: Bool
  let canClearValue: Bool
  let resetState: (FoodItemEditableCellResetMode) -> Void
  let content: Content

  init(
    title: LocalizedStringKey,
    mode: FoodItemEditableCellMode,
    isVertical: Bool = false,
    canClearValue: Bool = true,
    resetState: @escaping (FoodItemEditableCellResetMode) -> Void,
    @ViewBuilder contentBuilder: () -> Content
  ) {
    self.title = title
    self.mode = mode
    self.isVertical = isVertical
    self.canClearValue = canClearValue
    self.resetState = resetState
    self.content = contentBuilder()
  }

  var body: some View {
    Group {
      if isVertical {
        VStack(alignment: .leading) {
          contentView
        }
      } else {
        HStack {
          contentView
        }
      }
    }
    .animation(.easeInOut, value: mode)
  }
}

private extension FoodItemEditableCell {

  @ViewBuilder
  var contentView: some View {
    HStack {
      switch mode {
      case .value:
        if canClearValue {
          Button {
            resetState(.clearValue)
          } label: {
            Image(systemSymbol: .xmarkCircle)
              .foregroundStyle(.secondary)
          }
          .frame(height: 44)
        }
      case .modifiedValue:
        Button {
          resetState(.resetValue)
        } label: {
          Image(systemSymbol: .arrowUturnLeft)
            .foregroundStyle(.mutedOrange)
        }
        .frame(height: 44)
      }

      Text(title)
    }

    Spacer()

    content
  }
}

#Preview {
  VStack {
    VStack {
      FoodItemEditableCell(
        title: "Name",
        mode: .value,
        resetState: { (_) in },
        contentBuilder: {
          Text("Apples")
            .bold()
        }
      )
      FoodItemEditableCell(
        title: "Name",
        mode: .modifiedValue,
        resetState: { (_) in },
        contentBuilder: {
          Text("Apples")
            .bold()
        }
      )
    }
    .cardContainer()
    .padding()
  }
  .groupedBackground()
}
