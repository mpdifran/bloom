//
//  SwipeActionButtonStyle.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-26.
//

import SFSafeSymbols
import SwiftUI
import Swipy

struct SwipeActionButtonStyle: ButtonStyle {

  func makeBody(configuration: Configuration) -> some View {
    VStack {
      Spacer(minLength: 0)
      configuration.label
        .foregroundStyle(.tint)
        .horizontallyCentered()
      Spacer(minLength: 0)
    }
    .bold()
    .cardContainer(fill: .tint.tertiary)
    .aspectRatio(1, contentMode: .fit)
  }
}

extension ButtonStyle where Self == SwipeActionButtonStyle {
  static var swipeAction: some ButtonStyle { SwipeActionButtonStyle() }
}

struct SwipeActionStack<Content: View>: View {

  let content: () -> Content

  init(
    @ViewBuilder _ content: @escaping () -> Content
  ) {
    self.content = content
  }

  var body: some View {
    HStack {
      content()
    }
    .padding(.leading)
  }
}

struct SwipeActionButtonContent: View {
  let title: String
  let symbol: SFSymbol

  init(_ title: String, symbol: SFSymbol) {
    self.title = title
    self.symbol = symbol
  }

  var body: some View {
    ViewThatFits {
      VStack(spacing: 10) {
        Image(systemSymbol: symbol)
        Text(title)
          .font(.caption)
      }
      VStack(spacing: 5) {
        Image(systemSymbol: symbol)
        Text(title)
          .font(.caption)
      }
      Image(systemSymbol: symbol)
    }
  }
}

#Preview {
  @Previewable @State var isSwipingAnItem = false

  ScrollView {
    VStack {
      Swipy(
        isSwipingAnItem: $isSwipingAnItem,
        swipeBehavior: .soft,
        scrollBehavior: .soft
      ) { model in
        HStack {
          Text("Preview")
            .bold()
          Spacer()
          DisclosureIndicator()
        }
        .cardContainer()
      } actions: {
        SwipeActionStack {
          SwipyAction { model in
            Button {
              model.unswipe()
            } label: {
              SwipeActionButtonContent("Star", symbol: .star)
            }
            .buttonStyle(.swipeAction)
            .tint(.mutedYellow)
          }
          SwipyAction { model in
            Button {
              model.unswipe()
            } label: {
              SwipeActionButtonContent("Delete", symbol: .trash)
            }
            .buttonStyle(.swipeAction)
            .tint(.mutedRed)
          }
        }
      }

      Swipy(
        isSwipingAnItem: $isSwipingAnItem,
        swipeBehavior: .soft,
        scrollBehavior: .soft
      ) { model in
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
      } actions: {
        SwipeActionStack {
          SwipyAction { model in
            Button {
              model.unswipe()
            } label: {
              SwipeActionButtonContent("Favourite", symbol: .heart)
            }
            .buttonStyle(.swipeAction)
            .tint(.mutedBlue)
          }
          SwipyAction { model in
            Button {
              model.unswipe()
            } label: {
              SwipeActionButtonContent("Delete", symbol: .trash)
            }
            .buttonStyle(.swipeAction)
            .tint(.mutedRed)
          }
        }
      }
    }
    .padding()
  }
  .scrollDisabled(isSwipingAnItem)
  .groupedBackground()
}
