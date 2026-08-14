//
//  DebugMockBioAgeView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-07.
//

import SwiftUI
import CoreHealth

#if DEBUG
struct DebugMockBioAgeView: View {
  @State private var provider = BiologicalAgeProvider.shared

  var body: some View {
    List {
      mockToggleSection
      if provider.mockBioAgeEnabled {
        deltaSliderSection
      }
    }
    .listStyle(.carousel)
    .navigationTitle("Mock Bio Age")
  }
}

// MARK: - Sections

private extension DebugMockBioAgeView {

  var mockToggleSection: some View {
    Toggle("Enabled", isOn: $provider.mockBioAgeEnabled)
      .padding(.vertical, 8)
  }

  var deltaSliderSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Delta")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Text(provider.mockBioAgeDelta >= 0
          ? "+\(String(format: "%.1f", provider.mockBioAgeDelta))"
          : String(format: "%.1f", provider.mockBioAgeDelta))
          .font(.caption)
          .bold()
          .foregroundStyle(.white)
      }

      Slider(
        value: $provider.mockBioAgeDelta,
        in: -12...12,
        step: 0.5
      )

      HStack {
        Text(verbatim: "-12")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Spacer()
        Text(verbatim: "+12")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      DebugMockBioAgeView()
    }
  }
}
#endif
