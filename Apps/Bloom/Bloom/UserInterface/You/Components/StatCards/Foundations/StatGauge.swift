//
//  StatGauge.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI

private extension CGFloat {
  static let lineWidth: CGFloat = 16
}

struct StatGauge<Content: View>: View {
  let progress: CGFloat
  let color: Color
  @ViewBuilder let content: () -> Content

  init(
    progress: CGFloat,
    color: Color,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.progress = progress
    self.color = color
    self.content = content
  }

  private var clippedProgress: CGFloat {
    max(0, min(progress, 1))
  }

  var body: some View {
    GeometryReader { geometry in
      let dimension = min(geometry.size.width, geometry.size.height)

      ZStack {
        // Background ring
        Circle()
          .stroke(color.tertiary, lineWidth: .lineWidth)

        // Progress ring with gradient
        Circle()
          .trim(from: 0, to: clippedProgress)
          .stroke(
            AngularGradient(
              gradient: Gradient(colors: [color, color.lighter()]),
              center: .center,
              startAngle: .degrees(0),
              endAngle: .degrees(360)
            ),
            style: StrokeStyle(lineWidth: .lineWidth, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))

        // Start cap
        Circle()
          .frame(square: .lineWidth)
          .foregroundColor(clippedProgress > 0 ? color : .clear)
          .offset(y: -(dimension / 2 - .lineWidth / 2))

        // End cap with shadow
        Circle()
          .frame(square: .lineWidth)
          .foregroundColor(clippedProgress >= 0.95 ? color.lighter() : .clear)
          .offset(y: -(dimension / 2 - .lineWidth / 2))
          .rotationEffect(.degrees(360 * clippedProgress))
          .shadow(
            color: clippedProgress >= 0.96 ? .black.opacity(0.1) : .clear,
            radius: 3, x: 10, y: 0
          )

        // Center content
        content()
          .padding(.lineWidth + 4)
      }
      .padding(.lineWidth / 2)
      .frame(width: dimension, height: dimension)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .aspectRatio(1, contentMode: .fit)
    .animation(.bouncy(duration: 1.2), value: clippedProgress)
  }
}

extension StatGauge where Content == AnyView {
  init(
    progress: CGFloat,
    label: String?,
    color: Color
  ) {
    self.progress = progress
    self.color = color
    self.content = {
      AnyView(
        Group {
          if let label {
            Text(label)
              .font(.title)
              .fontWeight(.heavy)
              .fontDesign(.rounded)
              .minimumScaleFactor(0.5)
          }
        }
      )
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        StatGauge(
          progress: 0.3,
          label: "30%",
          color: .mutedPurple
        )
        StatGauge(
          progress: 0.75,
          label: "75%",
          color: .mutedGreen
        )
      }
      .padding()
    }
  }
}
