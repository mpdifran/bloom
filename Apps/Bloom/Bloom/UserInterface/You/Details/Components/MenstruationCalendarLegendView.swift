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
    case .none: "No Period"
    case .full: "Period"
    case .ring: "Predicted Ovulation"
    case .partial: "Likely Next Period"
    case .fadedPartial: "Less Likely Next Period"
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
