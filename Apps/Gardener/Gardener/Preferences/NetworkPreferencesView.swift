//
//  NetworkPreferencesView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-01-23.
//

import SwiftUI

struct NetworkPreferencesView: View {
  @StateObject private var apiHost = APIHost.shared

  var body: some View {
    Form {
      hostSection
    }
    .formStyle(.grouped)
    .tabItem {
      Label("Network", systemImage: "network")
    }
  }
}

private extension NetworkPreferencesView {

  var hostSection: some View {
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
      Text("Host")
    } footer: {
      HStack {
        Text("Resolved Host: \(apiHost.base.absoluteString)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .padding(.horizontal)
    }
  }
}

#Preview {
  NetworkPreferencesView()
}
