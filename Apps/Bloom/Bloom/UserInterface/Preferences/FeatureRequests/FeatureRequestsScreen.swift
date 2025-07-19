//
//  FeatureRequestsScreen.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import SwiftUI

struct FeatureRequestScreen: View {

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      FeatureRequestWebView()
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            DismissButton()
          }
        }
    }
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

#Preview {
  FeatureRequestScreen()
}
