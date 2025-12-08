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
        Text("Data Shared with AI")
          .font(.body)
          .bold()
        Text(aiDataSharingSettings.enabledCategoriesText)
          .font(.caption)
          .bold()
          .foregroundStyle(aiDataSharingSettings.enabledCategories.isEmpty ? .mutedRed : .secondary)
      }

      Spacer()

      DisclosureIndicator()
    }
    .fontDesign(.rounded)
  }
}

#Preview {
  AIDataShareCell()
}
