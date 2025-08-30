//
//  TodayViewSectionCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-27.
//

import SwiftUI
import AppUI

struct TodayViewSectionCell: View {
  let section: TodaySection

  @Binding var isEnabled: Bool
  @State private var presentedSheet: AnyView?

  @Environment(ThemeController.self) private var themeController

  private var hasBloomPlus: Bool {
    EntitlementController.shared.hasBloomPro == true
  }
  
  private var isLocked: Bool {
    section.requiresBloomPlus && !hasBloomPlus
  }

  var body: some View {
    HStack {
      Image(systemSymbol: .line3Horizontal)
        .font(.caption)
        .foregroundStyle(.tertiary)
        .opacity(isLocked ? 0.5 : 1)

      Image(systemSymbol: section.icon)
        .font(.body)
        .foregroundStyle(isLocked ? .tertiary : .secondary)
        .frame(width: 24)

      Text(section.displayName)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(isLocked ? .tertiary : .primary)
      
      if isLocked {
        Image(systemSymbol: .lockFill)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }

      Spacer()

      if isLocked {
        Toggle("", isOn: .constant(false))
          .disabled(true)
      } else {
        Toggle("", isOn: $isEnabled)
      }
    }
    .cardContainer()
    .onTapGesture {
      if isLocked {
        presentedSheet = BloomPlusPaywall(showDismiss: true)
          .tint(themeController.theme.color)
          .asAny
      }
    }
    .sheet($presentedSheet)
  }
}

#Preview {
  @Previewable @State var isEnabled = true

  PreviewEnvironment {
    BloomScrollView {
      TodayViewSectionCell(
        section: .goals,
        isEnabled: $isEnabled
      )
    }
  }
}
