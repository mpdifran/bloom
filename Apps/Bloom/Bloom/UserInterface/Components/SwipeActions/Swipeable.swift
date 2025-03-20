//
//  Swipeable.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-26.
//

import SFSafeSymbols
import SwiftUI
import DataContainer
import Swipy

struct SwipeAction: Identifiable {
  let id = UUID()
  let title: String
  let symbol: SFSymbol
  let tint: Color
  let action: () -> Void
}

struct Swipeable<Content: View>: View {
  @Binding private var isSwipingItem: Bool

  private let actions: [SwipeAction]
  private let contentBuilder: () -> Content

  init(
    isSwipingItem: Binding<Bool>,
    actions: [SwipeAction],
    contentBuilder: @escaping () -> Content
  ) {
    self._isSwipingItem = isSwipingItem
    self.actions = actions
    self.contentBuilder = contentBuilder
  }

  @State private var didTakeAction = false

  var body: some View {
    Swipy(
      isSwipingAnItem: $isSwipingItem
    ) { model in
      contentBuilder()
    } actions: {
      SwipeActionStack {
        ForEach(actions) { swipeAction in
          SwipyAction { model in
            Button {
              swipeAction.action()
              didTakeAction.toggle()
              withAnimation {
                model.unswipe()
              }
            } label: {
              SwipeActionButtonContent(
                swipeAction.title,
                symbol: swipeAction.symbol
              )
            }
            .buttonStyle(.swipeAction)
            .tint(swipeAction.tint)
          }
          .sensoryFeedback(.selection, trigger: didTakeAction)
        }
      }
    }
  }
}



#Preview {

  @Previewable @State var isSwipingItem = false

  ScrollView {
    VStack {
      Swipeable(
        isSwipingItem: $isSwipingItem,
        actions: [
          SwipeAction(
            title: "Star",
            symbol: .star,
            tint: .mutedYellow,
            action: { }
          ),
          SwipeAction(
            title: "Delete",
            symbol: .trash,
            tint: .mutedRed,
            action: { }
          )
        ]
      ) {
        HStack {
          Text("Preview")
            .bold()
          Spacer()
          DisclosureIndicator()
        }
        .cardContainer()
      }

      Swipeable(
        isSwipingItem: $isSwipingItem,
        actions: [
          SwipeAction(
            title: "Favourite",
            symbol: .heart,
            tint: .mutedBlue,
            action: { }
          ),
          SwipeAction(
            title: "Delete",
            symbol: .trash,
            tint: .mutedRed,
            action: { }
          )
        ]
      ) {
        HStack {
          VStack(alignment: .leading) {
            Text("Multi Layer")
            Text("Preview")
            Text("With Multiple Lines")
          }
          .bold()
          Spacer()
          DisclosureIndicator()
        }
        .cardContainer()
      }

      VStack {
        Swipeable(
          isSwipingItem: $isSwipingItem,
          actions: [
            SwipeAction(
              title: "Delete",
              symbol: .trash,
              tint: .mutedRed,
              action: { }
            )
          ]
        ) {
          FoodItemLogCell(
            foodItemLog: FoodItemLog(
              id: "123",
              name: nil,
              date: .now,
              meal: .breakfast,
              numberOfServings: 1,
              imageData: nil,
              foodItemServings: [
                FoodItemServing(
                  numberOfServings: 2,
                  foodItem: .Preview.ritzCrackers
                )
              ]
            ),
            showDetails: { (_) in

            }) { (_) in
              
            }
        }
      }
    }
    .padding()
  }
  .scrollDisabled(isSwipingItem)
  .groupedBackground()
}
