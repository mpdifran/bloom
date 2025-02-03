//
//  FoodItemEditableCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

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
  let title: String
  let mode: FoodItemEditableCellMode
  let isVertical: Bool
  let canClearValue: Bool
  let resetState: (FoodItemEditableCellResetMode) -> Void
  let content: Content

  init(
    title: String,
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
            Image(systemName: "xmark.circle")
              .foregroundStyle(.secondary)
          }
          .frame(height: 44)
        }
      case .modifiedValue:
        Button {
          resetState(.resetValue)
        } label: {
          Image(systemName: "arrow.uturn.left")
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
