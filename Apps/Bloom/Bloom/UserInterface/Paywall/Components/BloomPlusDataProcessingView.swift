//
//  BloomPlusDataProcessingView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-13.
//

import SwiftUI

struct BloomPlusDataProcessingView: View {
  var body: some View {
    TodayCardCell(
      symbol: .sparkles,
      title: "Personal Data Processing",
      content: String(localized: "Bloom Plus processes de-identified summaries of your personal data securely with OpenAI to generate personalized insights.", comment: "Body of the paywall card explaining how personal data is processed."),
      color: .mutedLightBlue
    ) {
      Button {

      } label: {
        Text("Learn More")
          .bold()
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BloomPlusDataProcessingView()
    }
  }
}
