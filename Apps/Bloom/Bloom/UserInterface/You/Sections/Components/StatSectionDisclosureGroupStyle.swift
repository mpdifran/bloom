//
//  StatSectionDisclosureGroupStyle.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI

struct StatSectionDisclosureGroupStyle: DisclosureGroupStyle {
  @State private var selectionToggle = false

  func makeBody(configuration: Configuration) -> some View {
    VStack {
      configuration.label
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
    .padding(.top)
    .animation(.easeInOut, value: configuration.isExpanded)
    .sensoryFeedback(.selection, trigger: selectionToggle)
  }
}

extension DisclosureGroupStyle where Self == StatSectionDisclosureGroupStyle {
  static var statSection: StatSectionDisclosureGroupStyle { StatSectionDisclosureGroupStyle() }
}
