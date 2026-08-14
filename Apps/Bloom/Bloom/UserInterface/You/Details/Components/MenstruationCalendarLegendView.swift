//
//  MenstruationCalendarLegendView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-28.
//

import SwiftUI

struct MenstruationCalendarLegendView: View {
  var body: some View {
    LazyVGrid(
      columns: [
        GridItem(.adaptive(minimum: 100, maximum: 200)),
        GridItem(.adaptive(minimum: 100, maximum: 200))
      ],
      alignment: .leading
    ) {
      ForEach(DayCapsule.HighlightKind.allCases, id: \.self) { kind in
        LegendLabel(kind: kind)
      }
    }
    .cardContainer()
  }
}

private extension MenstruationCalendarLegendView {
  struct LegendLabel: View {
    let kind: DayCapsule.HighlightKind

    var body: some View {
      HStack {
        circleView
          .frame(square: 16)

        Text(title)
          .font(.caption)
      }
    }
  }
}

private extension MenstruationCalendarLegendView.LegendLabel {

  @ViewBuilder
  var circleView: some View {
    switch kind {
    case .none:
      Circle()
        .fill(.background.secondary)
    case .full:
      Circle()
        .fill(.mutedPink)
    case .ring:
      Circle()
        .fill(.mutedBlue.secondary)
        .overlay {
          Circle()
            .stroke(.mutedBlue, lineWidth: 2)
        }
    case .partial:
      Circle()
        .fill(ShaderLibrary.Stripes(
          .float(2),
          .colorArray([
            .mutedPink,
            .mutedPink.opacity(0.6)
          ])
        ))
        .rotationEffect(.degrees(-45))
    case .fadedPartial:
      Circle()
        .fill(ShaderLibrary.Stripes(
          .float(2),
          .colorArray([
            .mutedPink.opacity(0.5),
            .mutedPink.opacity(0.2)
          ])
        ))
        .rotationEffect(.degrees(-45))
    }
  }

  var title: String {
    switch kind {
    case .none: String(localized: "No Period", comment: "Title for legend label")
    case .full: String(localized: "Period", comment: "Title for legend label")
    case .ring: String(localized: "Predicted Ovulation", comment: "Title for legend label")
    case .partial: String(localized: "Likely Next Period", comment: "Title for legend label")
    case .fadedPartial: String(localized: "Less Likely Next Period", comment: "Title for legend label")
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MenstruationCalendarLegendView()
    }
  }
}
