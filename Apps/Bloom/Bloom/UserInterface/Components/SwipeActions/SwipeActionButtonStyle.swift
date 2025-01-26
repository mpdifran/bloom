//
//  SwipeActionButtonStyle.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-26.
//

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
  let systemImage: String

  init(_ title: String, systemImage: String) {
    self.title = title
    self.systemImage = systemImage
  }

  var body: some View {
    ViewThatFits {
      VStack(spacing: 10) {
        Image(systemName: systemImage)
        Text(title)
          .font(.caption)
      }
      VStack(spacing: 5) {
        Image(systemName: systemImage)
        Text(title)
          .font(.caption)
      }
      Image(systemName: systemImage)
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
              SwipeActionButtonContent("Star", systemImage: "star")
            }
            .buttonStyle(.swipeAction)
            .tint(.mutedYellow)
          }
          SwipyAction { model in
            Button {
              model.unswipe()
            } label: {
              SwipeActionButtonContent("Delete", systemImage: "trash")
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
              SwipeActionButtonContent("Favourite", systemImage: "heart")
            }
            .buttonStyle(.swipeAction)
            .tint(.mutedBlue)
          }
          SwipyAction { model in
            Button {
              model.unswipe()
            } label: {
              SwipeActionButtonContent("Delete", systemImage: "trash")
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
