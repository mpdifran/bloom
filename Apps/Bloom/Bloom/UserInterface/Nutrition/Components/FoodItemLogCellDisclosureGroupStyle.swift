//
//  FoodItemLogCellDisclosureGroupStyle.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-19.
//

import SwiftUI

extension DisclosureGroupStyle where Self == FoodItemLogCellDisclosureGroupStyle {

  static var foodItemLogCell: some DisclosureGroupStyle { FoodItemLogCellDisclosureGroupStyle() }
}

struct FoodItemLogCellDisclosureGroupStyle: DisclosureGroupStyle {

  @State private var selectionToggle = false

  func makeBody(configuration: Configuration) -> some View {
    VStack(spacing: 0) {
      HStack {
        configuration.label
        Spacer()
        Image(systemSymbol: .chevronDown)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
          .rotationEffect(.degrees(configuration.isExpanded ? -180 : 0))
      }
      .padding(.trailing)
      .selectable()
      .onTapGesture {
        withAnimation {
          configuration.isExpanded.toggle()
        }
        selectionToggle.toggle()
      }

      if configuration.isExpanded {
        configuration.content
          .transition(.opacity)
      }
    }
    .animation(.easeInOut, value: configuration.isExpanded)
    .cardContainer(includePadding: false)
    .sensoryFeedback(.selection, trigger: selectionToggle)
  }
}

#Preview {
@Previewable @State var isExpanded = false

  PreviewEnvironment {
    ScrollView {
      VStack {
        DisclosureGroup(isExpanded: $isExpanded) {
          Text("This is the content")
            .padding()
        } label: {
          Text("This is the label")
            .padding()
        }
        .disclosureGroupStyle(.foodItemLogCell)
      }
      .padding()
    }
    .groupedBackground()
  }
}
