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

  @AppStorage private var selectedOverride: String

  init(experimentId: String, experimentName: String) {
    self.experimentId = experimentId
    self.experimentName = experimentName
    let key = String.ExperimentOverrideKey.key(for: experimentId)
    self._selectedOverride = AppStorage(wrappedValue: ExperimentOverride.original.rawValue, key)
  }

  var body: some View {
    SettingsCell(experimentName) {
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
        ExperimentOverrideView(experimentId: .ExperimentID.onboardingHealthKitView, experimentName: "Onboarding HealthKit View")
      }
    }
  }
}
