//
//  PreferencesView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-01-23.
//

import SwiftUI

struct PreferencesView: View {
  var body: some View {
    NavigationStack {
      TabView {
        AccountPreferencesView()
        NetworkPreferencesView()
      }
    }
    .frame(
      width: 700,
      height: 450
    )
  }
}

#Preview {
  PreferencesView()
}
