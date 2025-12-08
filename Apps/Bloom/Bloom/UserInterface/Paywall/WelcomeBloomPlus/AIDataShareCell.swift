//
//  AIDataShareCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-08.
//

import SwiftUI
import BloomUI

struct AIDataShareCell: View {
  @ObservedObject private var aiDataSharingSettings = AIDataSharingSettings.shared

  var body: some View {
    HStack {
      AIDataShareIcon()

      VStack(alignment: .leading) {
        Text("Personal Data Categories")
          .font(.body)
          .bold()

        Text("Select which categories are shared with AI.")
          .font(.caption)
          .fixedSize(horizontal: false, vertical: true)
          .foregroundStyle(.secondary)

        Text(aiDataSharingSettings.enabledCategoriesText)
          .font(.caption)
          .fixedSize(horizontal: false, vertical: true)
          .foregroundStyle(aiDataSharingSettings.enabledCategories.isEmpty ? .mutedRed : .secondary)
      }
      .multilineTextAlignment(.leading)

      Spacer()

      DisclosureIndicator()
    }
    .fontDesign(.rounded)
  }
}

#Preview {
  AIDataShareCell()
}
