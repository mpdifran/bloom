//
//  SummaryMetricView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import SwiftUI

struct SummaryMetricView<Content: View>: View {
  let title: String
  let contentBuilder: () -> Content

  init(
    title: String,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.title = title
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.system(.caption2, weight: .bold))
        .foregroundStyle(.tint)

      contentBuilder()
    }
    .horizontalAlignment(.leading)
    .padding(6)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(.background.secondary)
    }
  }
}

extension SummaryMetricView where Content == Text {
  init(title: String, value: String) {
    self.title = title
    self.contentBuilder = {
      Text(value)
        .font(.system(.title2, design: .rounded, weight: .bold).lowercaseSmallCaps())
    }
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      VStack(alignment: .leading) {
        SummaryMetricView(
          title: "Duration",
          value: "13m4s"
        )
        .tint(.mutedYellow)
      }
    }
    .navigationTitle("Summary")
    .navigationBarTitleDisplayMode(.inline)
  }
}
