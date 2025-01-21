//
//  OptionsView.swift
//  Gardener
//
//  Created by Zach Radford on 2025-01-19.
//

import SwiftUI

struct OptionsView: View {
  @StateObject private var apiHost = APIHost.shared

  var body: some View {
    Form {
      Section(header: Text("Dev Options")) {
        networkSection
      }
    }
    .formStyle(.grouped)
  }
}

private extension OptionsView {
  var networkSection: some View {
    Section {
      Toggle("Override Host", isOn: apiHost.$overrideEnabled)

      if apiHost.overrideEnabled {
        LabeledContent("Host") {
          TextField(
            "",
            text: apiHost.$overrideBase,
            prompt: Text("ex: 192.168.1.1")
          )
        }
      }
    } header: {
      Text("Network")
    } footer: {
      Text(apiHost.base.absoluteString)
    }
  }
}
