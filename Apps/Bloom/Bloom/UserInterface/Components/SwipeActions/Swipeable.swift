//
//  Swipeable.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-26.
//

import SwiftUI
import Swipy

struct SwipeAction: Identifiable {
  let id = UUID()
  let title: String
  let systemImage: String
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
      isSwipingAnItem: $isSwipingItem,
      swipeBehavior: .straight
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
                systemImage: swipeAction.systemImage
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
          .init(
            title: "Star",
            systemImage: "star",
            tint: .mutedYellow,
            action: { }
          ),
          .init(
            title: "Delete",
            systemImage: "trash",
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
          .init(
            title: "Favourite",
            systemImage: "heart",
            tint: .mutedBlue,
            action: { }
          ),
          .init(
            title: "Delete",
            systemImage: "trash",
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
    }
    .padding()
  }
  .scrollDisabled(isSwipingItem)
  .groupedBackground()
}
