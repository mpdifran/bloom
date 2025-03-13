//
//  ThemeSelectionCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-13.
//

import SwiftUI

struct ThemeSelectionCard: View {
  @Environment(ThemeController.self) private var themeController
  @Environment(\.dismiss) private var dismiss

  @State private var themeSelectionToggle = false

  var body: some View {
    CardView {
      LargeTitleActionCard("Select a Theme") {
        ForEach(ThemeController.Theme.allCases) { theme in
          ThemeSelectionCell(theme: theme, isSelected: themeController.theme == theme)
            .onTapGesture {
              guard theme != themeController.theme else { return }

              themeSelectionToggle.toggle()
              Task {
                await themeController.set(theme: theme)
              }
            }
        }

        Button {
          dismiss()
        } label: {
          Text("Done")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .padding(.top)
        .padding(.top)
      }
    }
    .sensoryFeedback(.impact, trigger: themeSelectionToggle)
    .animation(.default, value: themeController.theme)
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      ThemeSelectionCard()
    }
  }
}
