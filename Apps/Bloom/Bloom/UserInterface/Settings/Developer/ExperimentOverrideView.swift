//
//  ExperimentOverrideView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-05.
//

import SwiftUI
import AppUI

struct ExperimentOverrideView: View {
  let experimentId: String
  let experimentName: String

  @Environment(ExperimentManager.self) private var experimentManager
  @AppStorage private var selectedOverride: String

  init(experimentId: String, experimentName: String) {
    self.experimentId = experimentId
    self.experimentName = experimentName
    let key = String.ExperimentOverrideKey.key(for: experimentId)
    self._selectedOverride = AppStorage(wrappedValue: ExperimentOverride.original.rawValue, key)
  }

  var body: some View {
    let identifier = ExperimentIdentifier(experimentId)
    let currentVariant = experimentManager.variant(for: identifier)
    
    SettingsCell(
      experimentName,
      subtitle: "Current: \(currentVariant == .control ? "Control" : "Treatment")"
    ) {
      Picker("", selection: $selectedOverride) {
        ForEach(ExperimentOverride.allCases, id: \.rawValue) { override in
          Text(override.displayName)
            .tag(override.rawValue)
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      SettingsSectionContainer {
        ExperimentOverrideView(experimentId: ExperimentIdentifier.onboardingPaywall.value, experimentName: "Onboarding Paywall")
      }
    }
  }
}
