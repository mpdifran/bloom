//
//  LargeTitleActionCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-17.
//

import SwiftUI

struct LargeTitleActionCard<Content, LeadingContent, TrailingContent>: View where Content: View, LeadingContent: View, TrailingContent: View {
  let title: String
  let includePadding: Bool
  let contentBuilder: () -> Content
  let leadingContentBuilder: () -> LeadingContent
  let trailingContentBuilder: () -> TrailingContent

  init(
    _ title: String,
    includePadding: Bool = true,
    @ViewBuilder contentBuilder: @escaping () -> Content,
    @ViewBuilder leading: @escaping () -> LeadingContent = { EmptyView() },
    @ViewBuilder trailing: @escaping () -> TrailingContent = { EmptyView() }
  ) {
    self.title = title
    self.includePadding = includePadding
    self.contentBuilder = contentBuilder
    self.leadingContentBuilder = leading
    self.trailingContentBuilder = trailing
  }

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        ZStack {
          trailingContentBuilder()
            .opacity(0)
          leadingContentBuilder()
        }
        .labelStyle(.iconOnly)
        .bold()
        .frame(minWidth: 44, minHeight: 44)

        Spacer()

        Text(title)
          .font(.title)
          .fontDesign(.rounded)
          .bold()
          .lineLimit(1)
          .minimumScaleFactor(0.3)

        Spacer()

        ZStack {
          leadingContentBuilder()
            .opacity(0)
          trailingContentBuilder()
        }
        .labelStyle(.iconOnly)
        .bold()
        .frame(minWidth: 44, minHeight: 44)
      }

      VStack {
        contentBuilder()
      }
      .padding(.top)
    }
    .if(includePadding) {
      $0.padding()
    }
  }
}

#Preview {
  PreviewSheetPresent {
    CardView {
      LargeTitleActionCard("Actions") {
        Text("Hello World")
      } trailing: {
        Button("Add", systemImage: "plus") {

        }
      }
    }
    .tint(.mutedBlue)
  }
}
