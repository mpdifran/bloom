//
//  View+Preferences.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import SwiftUI

extension View {

  func backgroundPreference<K>(
    key: K.Type = K.self,
    valueBuilder: @escaping (GeometryProxy) -> K.Value
  ) -> some View where K: PreferenceKey {
    background {
      GeometryReader { proxy in
        Color.clear.preference(key: key, value: valueBuilder(proxy))
      }
    }
  }
}
