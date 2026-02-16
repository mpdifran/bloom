//
//  WorkoutEffortBarView.swift
//  CoreHealth
//
//  Created by Mark DiFranco on 2026-02-11.
//

import SwiftUI

public struct WorkoutEffortBarView: View {
  @Binding var selectedEffort: Int

  private let categories = WorkoutEffortCategory.allCases
  private let barSpacing: CGFloat = 8
  private let dotSize: CGFloat = 6
  private let barHeight: CGFloat

  public init(selectedEffort: Binding<Int>, barHeight: CGFloat = 220) {
    _selectedEffort = selectedEffort
    self.barHeight = barHeight
  }

  public var body: some View {
    GeometryReader { geometry in
      let totalWidth = geometry.size.width
      let viewHeight = geometry.size.height
      let totalUnits = CGFloat(categories.reduce(0) { $0 + $1.range.count })
      let availableWidth = totalWidth - barSpacing * CGFloat(categories.count - 1)
      let capsuleWidth = availableWidth / totalUnits
      let cornerRadius = capsuleWidth / 2
      let minLeftHeight = capsuleWidth * 3 / 4
      let layouts = barLayouts(capsuleWidth: capsuleWidth, minLeftHeight: minLeftHeight, viewHeight: viewHeight)

      ZStack(alignment: .bottom) {
        HStack(alignment: .bottom, spacing: barSpacing) {
          ForEach(Array(categories.enumerated()), id: \.element) { index, category in
            effortBar(
              category: category,
              barHeight: layouts[index].height,
              barWidth: layouts[index].width,
              capsuleWidth: capsuleWidth,
              cornerRadius: cornerRadius
            )
          }
        }

        // Draggable thumb
        thumbIndicator(
          viewHeight: viewHeight,
          capsuleWidth: capsuleWidth,
          layouts: layouts
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            let newEffort = effortLevel(for: value.location.x, layouts: layouts)
            if newEffort != selectedEffort {
              selectedEffort = newEffort
            }
          }
      )
    }
    .frame(height: barHeight)
    .sensoryFeedback(.impact(flexibility: .soft), trigger: selectedEffort)
  }
}

// MARK: - Bar Components

private extension WorkoutEffortBarView {

  func effortBar(
    category: WorkoutEffortCategory,
    barHeight: CGFloat,
    barWidth: CGFloat,
    capsuleWidth: CGFloat,
    cornerRadius: CGFloat
  ) -> some View {
    let activeColor = WorkoutEffortCategory.category(for: selectedEffort).color
    let fillWidth = activeFillWidth(for: category, barWidth: barWidth, capsuleWidth: capsuleWidth)
    let fillHeight = barHeight - (barWidth - fillWidth) / 2

    return ZStack(alignment: .bottomLeading) {
      EffortBarShape(capsuleWidth: capsuleWidth)
        .fill(Color.white.opacity(0.15))
        .frame(width: barWidth, height: barHeight)

      if fillWidth > 0 {
        EffortBarShape(capsuleWidth: capsuleWidth)
          .fill(activeColor)
          .frame(width: fillWidth, height: fillHeight)
      }
    }
    .frame(width: barWidth, height: barHeight)
      .overlay(alignment: .bottom) {
        dotsOverlay(category: category, capsuleWidth: capsuleWidth)
          .padding(.bottom, cornerRadius - dotSize / 2)
      }
      .animation(.easeInOut(duration: 0.2), value: selectedEffort)
  }

  func activeFillWidth(
    for category: WorkoutEffortCategory,
    barWidth: CGFloat,
    capsuleWidth: CGFloat
  ) -> CGFloat {
    if selectedEffort > category.range.upperBound {
      return barWidth
    } else if selectedEffort >= category.range.lowerBound {
      let levelInCategory = selectedEffort - category.range.lowerBound
      let levelsInCategory = category.range.count
      if levelsInCategory == 1 {
        return barWidth / 2 + capsuleWidth / 2
      }
      let fraction = CGFloat(levelInCategory) / CGFloat(levelsInCategory - 1)
      let capsuleCenterX = capsuleWidth / 2 + fraction * (barWidth - capsuleWidth)
      return capsuleCenterX + capsuleWidth / 2
    } else {
      return 0
    }
  }

  func dotsOverlay(category: WorkoutEffortCategory, capsuleWidth: CGFloat) -> some View {
    HStack(spacing: 0) {
      ForEach(Array(category.range.enumerated()), id: \.element) { index, level in
        if index > 0 { Spacer(minLength: 0) }
        Circle()
          .fill(.secondary)
          .frame(width: dotSize, height: dotSize)
      }
    }
    .padding(.horizontal, capsuleWidth / 2 - dotSize / 2)
  }

  func thumbIndicator(
    viewHeight: CGFloat,
    capsuleWidth: CGFloat,
    layouts: [BarLayout]
  ) -> some View {
    let category = WorkoutEffortCategory.category(for: selectedEffort)
    let categoryIndex = categories.firstIndex(of: category) ?? 0
    let layout = layouts[categoryIndex]
    let xPosition = thumbXPosition(capsuleWidth: capsuleWidth, layouts: layouts)

    // Height of the shape at the capsule's X (diagonal drops by (width - x) / 2)
    let xInBar = xPosition - layout.startX
    let shapeHeightAtX = layout.height - (layout.width - xInBar) / 2
    return Capsule(style: .circular)
      .fill(.white)
      .frame(width: capsuleWidth, height: shapeHeightAtX)
      .position(x: xPosition, y: viewHeight - shapeHeightAtX / 2)
      .animation(.easeInOut(duration: 0.2), value: selectedEffort)
  }
}

// MARK: - Layout Calculations

private extension WorkoutEffortBarView {

  struct BarLayout {
    let startX: CGFloat
    let width: CGFloat
    let height: CGFloat
  }

  /// Builds per-bar layouts with widths proportional to level count
  /// and heights that keep a continuous 1/2-slope diagonal across all bars.
  func barLayouts(capsuleWidth: CGFloat, minLeftHeight: CGFloat, viewHeight: CGFloat) -> [BarLayout] {
    var layouts: [BarLayout] = []
    var currentX: CGFloat = 0

    for category in categories {
      let width = capsuleWidth * CGFloat(category.range.count)
      let rightEdgeX = currentX + width
      // Global diagonal at slope 1/2: height = rightEdgeX * 0.5 + base
      let height = rightEdgeX * 0.5 + minLeftHeight
      layouts.append(BarLayout(startX: currentX, width: width, height: height))
      currentX = rightEdgeX + barSpacing
    }

    // Scale heights proportionally so the tallest bar fills the available view height
    let maxHeight = layouts.map(\.height).max() ?? 1
    if maxHeight > 0 && maxHeight != viewHeight {
      let scale = viewHeight / maxHeight
      layouts = layouts.map {
        BarLayout(startX: $0.startX, width: $0.width, height: $0.height * scale)
      }
    }

    return layouts
  }

  func thumbXPosition(capsuleWidth: CGFloat, layouts: [BarLayout]) -> CGFloat {
    let category = WorkoutEffortCategory.category(for: selectedEffort)
    guard let categoryIndex = categories.firstIndex(of: category) else { return 0 }

    let layout = layouts[categoryIndex]
    let levelInCategory = selectedEffort - category.range.lowerBound
    let levelsInCategory = category.range.count

    if levelsInCategory == 1 {
      return layout.startX + layout.width / 2
    }

    let inset = capsuleWidth / 2
    let fraction = CGFloat(levelInCategory) / CGFloat(levelsInCategory - 1)
    return layout.startX + inset + fraction * (layout.width - capsuleWidth)
  }

  func effortLevel(for xPosition: CGFloat, layouts: [BarLayout]) -> Int {
    for (categoryIndex, category) in categories.enumerated() {
      let layout = layouts[categoryIndex]
      let barEndX = layout.startX + layout.width

      if xPosition >= layout.startX && xPosition <= barEndX {
        let relativeX = xPosition - layout.startX
        let levelsInCategory = category.range.count
        let levelIndex = Int((relativeX / layout.width) * CGFloat(levelsInCategory))
        let clampedIndex = min(max(levelIndex, 0), levelsInCategory - 1)
        return category.range.lowerBound + clampedIndex
      }

      // Handle tap in gap between bars
      if categoryIndex < categories.count - 1 {
        let nextLayout = layouts[categoryIndex + 1]
        if xPosition > barEndX && xPosition < nextLayout.startX {
          let gapMid = (barEndX + nextLayout.startX) / 2
          return xPosition < gapMid
            ? category.range.upperBound
            : categories[categoryIndex + 1].range.lowerBound
        }
      }
    }

    // Clamp to edges
    if xPosition <= 0 { return 1 }
    return 10
  }
}

// MARK: - Bar Shape

/// A bar shape with an angled top-left diagonal creating an ascending silhouette.
///
/// The geometry uses a constant `capsuleWidth` for corner radius and a slope
/// of 1/2 across the full bar width. Bars with fewer levels are narrower but
/// share the same corner radius and diagonal slope.
struct EffortBarShape: Shape {
  let capsuleWidth: CGFloat

  func path(in rect: CGRect) -> Path {
    let r = capsuleWidth / 2
    let diagonalDrop = min(rect.width / 2, rect.height)

    // Corner vertices (before rounding)
    let topRight = CGPoint(x: rect.maxX, y: rect.minY)
    let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
    let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
    let topLeft = CGPoint(x: rect.minX, y: rect.minY + diagonalDrop)

    var path = Path()

    // Start on the left edge between the two left corners
    path.move(to: CGPoint(x: rect.minX, y: (topLeft.y + bottomLeft.y) / 2))

    // Bottom-left corner
    path.addArc(tangent1End: bottomLeft, tangent2End: bottomRight, radius: r)

    // Bottom-right corner
    path.addArc(tangent1End: bottomRight, tangent2End: topRight, radius: r)

    // Top-right corner (right edge meets diagonal)
    path.addArc(tangent1End: topRight, tangent2End: topLeft, radius: r)

    // Top-left corner (diagonal meets left edge)
    path.addArc(tangent1End: topLeft, tangent2End: bottomLeft, radius: r)

    path.closeSubpath()
    return path
  }
}

// MARK: - Preview

#Preview {
  VStack {
    WorkoutEffortBarView(selectedEffort: .constant(7))
      .padding(.horizontal, 32)
    Spacer()
  }
  .padding()
}
