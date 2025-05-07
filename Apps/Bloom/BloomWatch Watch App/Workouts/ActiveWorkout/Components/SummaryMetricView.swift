//
//  SummaryMetricView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI

struct SummaryMetricView: View {
  var title: String
  var value: String

  var body: some View {
    Text(title)
      .foregroundStyle(.foreground)
    Text(value)
      .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
    Divider()
  }
}
