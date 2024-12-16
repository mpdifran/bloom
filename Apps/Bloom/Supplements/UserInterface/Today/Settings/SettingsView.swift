//
//  SettingsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SwiftUI

struct SettingsView: View {
  var body: some View {
    List {
      healthGoalsSection
    }
  }
}

extension SettingsView {

  var healthGoalsSection: some View {
    Section("Health Goals") {

    }
  }
}

#Preview {
  SettingsView()
}
