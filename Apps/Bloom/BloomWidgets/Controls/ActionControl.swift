//
//  ActionControl.swift
//  BloomWidgets
//
//  Created by Mark DiFranco on 2025-10-14.
//

import AppIntents
import SwiftUI
import WidgetKit
import SFSafeSymbols

struct ActionControl: ControlWidget {
  static let kind: String = "com.lotus-labs.bloom.ActionControl"

  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(
      kind: Self.kind,
      intent: ActionControlIntent.self
    ) { configuration in
      ControlWidgetButton(action: OpenActionIntent(actionType: configuration.actionType)) {
        Label(configuration.actionType.label, systemSymbol: configuration.actionType.sfSymbol)
      }
    }
    .displayName("Log Health Data")
    .description("Quickly log health data.")
  }
}
