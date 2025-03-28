//
//  SegmentedPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI
import AppUI

private extension CGFloat {
  static let cornerRadius: CGFloat = 16
  static let selectionIndicatorPadding: CGFloat = 8
  static let componentHeight: CGFloat = 50
}

private extension Double {
  static let velocityMultiplier: Double = 0.2
}

protocol NamedCaseIterable: CaseIterable, Identifiable, Equatable {
  var name: String { get }
}

extension NamedCaseIterable {
  var id: Self { self }
}

struct SegmentedPicker<Enum>: View where Enum: NamedCaseIterable {
  @Binding var selectedValue: Enum

  @State private var dragOffset: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      let segmentWidth = geometry.size.width / CGFloat(options.count)
      ZStack(alignment: .leading) {

        RoundedRectangle(cornerRadius: .cornerRadius)
          .fill(.background)
          .frame(height: geometry.size.height)

        RoundedRectangle(cornerRadius: .cornerRadius - .selectionIndicatorPadding)
          .fill(.background.secondary)
          .frame(
            width: segmentWidth - 2 * CGFloat.selectionIndicatorPadding,
            height: geometry.size.height - 2 * CGFloat.selectionIndicatorPadding
          )
          .offset(x: calculateCurrentX(for: segmentWidth) + dragOffset)
          .animation(.easeInOut(duration: 0.3), value: selectedValue)

        HStack(spacing: 0) {
          ForEachEnumerated(options) { (index, option) in
            Text(option.name)
              .font(.system(size: 14))
              .fontWeight(.heavy)
              .fontDesign(.rounded)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .selectable()
              .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                  selectedValue = option
                }
              }
          }
        }
      }
      .simultaneousGesture(
        DragGesture()
          .onChanged { value in
            // Calculate new offset while ensuring it stays within bounds.
            let newOffset = value.translation.width
            let currentX = calculateCurrentX(for: segmentWidth)
            if currentX + newOffset >= 0 && currentX + newOffset <= geometry.size.width - (segmentWidth - .selectionIndicatorPadding) {
              dragOffset = newOffset
            }
          }
          .onEnded { value in
            let predictedOffset = value.translation.width + value.velocity.width * .velocityMultiplier
            let finalX = calculateCurrentX(for: segmentWidth) + predictedOffset
            let indexFloat = (finalX - CGFloat.selectionIndicatorPadding) / segmentWidth
            var newIndex = Int(round(indexFloat))
            newIndex = min(max(newIndex, 0), options.count - 1)

            withAnimation(.easeInOut(duration: 0.3)) {
              selectedValue = options[newIndex]
              dragOffset = 0
            }
          }
      )
      .sensoryFeedback(.selection, trigger: selectedValue)
    }
    .frame(height: .componentHeight)
  }
}

private extension SegmentedPicker {

  var options: [Enum] {
    Array(type(of: selectedValue).allCases)
  }

  var selectedIndex: Int {
    options.firstIndex(where: { $0 == selectedValue }) ?? 0
  }

  func calculateCurrentX(for segmentWidth: CGFloat) -> CGFloat {
    (CGFloat(selectedIndex) * segmentWidth) + CGFloat.selectionIndicatorPadding
  }
}

enum Option: String, NamedCaseIterable {
  case first = "First"
  case second = "Second"
  case third = "Third"

  var name: String {
    rawValue
  }
}

#Preview {
  @Previewable @State var option = Option.first

  PreviewEnvironment {
    VStack {
      Spacer()
      SegmentedPicker(selectedValue: $option)

      Text("Selected: \(option.name)")
      Spacer()
    }
    .padding()
    .groupedBackground()
  }
}
