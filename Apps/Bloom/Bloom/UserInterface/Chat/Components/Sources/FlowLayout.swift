//
//  FlowLayout.swift
//  Bloom
//

import SwiftUI

/// Lays subviews out left to right, wrapping onto a new line when the next one won't fit.
///
/// `HStack` would push a row of citation chips off the edge and `LazyVGrid` would force them onto
/// a fixed column width, which looks wrong when site names vary from "Yelp" to "Cleveland Clinic".
struct FlowLayout: Layout {
  var spacing: CGFloat = 6
  var lineSpacing: CGFloat = 6

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    let rows = rows(for: subviews, maxWidth: maxWidth)

    let height = rows.reduce(into: CGFloat.zero) { total, row in
      total += row.height
    } + lineSpacing * CGFloat(max(rows.count - 1, 0))

    let width = rows.map(\.width).max() ?? 0

    return CGSize(width: min(width, maxWidth), height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let rows = rows(for: subviews, maxWidth: bounds.width)
    var y = bounds.minY

    for row in rows {
      var x = bounds.minX
      for index in row.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        subviews[index].place(
          at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
          proposal: ProposedViewSize(size)
        )
        x += size.width + spacing
      }
      y += row.height + lineSpacing
    }
  }

  private struct Row {
    var indices: [Int] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
    var rows = [Row]()
    var current = Row()

    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width

      if needed > maxWidth, !current.indices.isEmpty {
        rows.append(current)
        current = Row()
        current.indices = [index]
        current.width = size.width
        current.height = size.height
      } else {
        current.indices.append(index)
        current.width = needed
        current.height = max(current.height, size.height)
      }
    }

    if !current.indices.isEmpty {
      rows.append(current)
    }

    return rows
  }
}
