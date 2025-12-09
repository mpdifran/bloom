//
//  ExistingUserConsentContainerView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-09.
//

import SwiftUI
import TelemetryDeck

struct ExistingUserConsentContainerView: View {
  let missingConsentTypes: [ConsentManager.ConsentType]

  init(missingConsentTypes: [ConsentManager.ConsentType]) {
    self.missingConsentTypes = missingConsentTypes

    if !missingConsentTypes.contains(.healthData) {
      isShowingAIConsent = true
    }
  }

  @State private var isShowingAIConsent = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    Group {
      if !isShowingAIConsent {
        ExistingUserHealthDataConsentView() {
          checkForAIConsent()
        }
      } else {
        ExistingUserAIDataConsentView() {
          finish()
        }
      }
    }
    .animation(.default, value: isShowingAIConsent)
    .presentationCompactAdaptation(.fullScreenCover)
  }
}

private extension ExistingUserConsentContainerView {

  func checkForAIConsent() {
    if EntitlementController.shared.hasBloomPro == true && missingConsentTypes.contains(.aiFeatures) {
      isShowingAIConsent = true
    } else {
      finish()
    }
  }

  func finish() {
    ConsentManager.shared.markConsentAsChecked()
    dismiss()
  }
}

#Preview {
  PreviewEnvironment {
    ExistingUserConsentContainerView(missingConsentTypes: [.healthData, .aiFeatures])
  }
}
