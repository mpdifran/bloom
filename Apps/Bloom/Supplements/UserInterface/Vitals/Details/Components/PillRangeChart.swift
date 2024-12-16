//
//  PillRangeChart.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-06.
//

import SwiftUI
import HealthKit

private extension CGFloat {
  static let barHeight: CGFloat = 20
}
struct PillRangeChart: View {
  let title: String
  let quantityString: String
  let unitString: String
  let value: Double
  let minValue: Double
  let maxValue: Double

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(title)
          .bold()

        Spacer()

        Text(quantityString)
          .font(.headline)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal)

      GeometryReader { proxy in
        ZStack {
          Rectangle()
            .fill(.fill)
            .frame(height: .barHeight)

          Rectangle()
            .fill(.tint)
            .frame(width: currentValuePoint(proxy: proxy), height: .barHeight)
            .zStackAlignment(.leading)

          HStack {
            Spacer()

            if value < minValue {
              PillValueLabelView(title: "\(value.format())\(unitString)")
              Spacer()
            }

            VStack {
              Text("Goal")
                .foregroundStyle(.tint)
                .bold()
                .opacity(isWithinRange ? 0 : 1)
              Spacer()
              HStack {
                Text("\(minValue.format())\(unitString)")
                  .foregroundStyle(value > minValue ? .white : .primary)
                Spacer()
                Text("\(maxValue.format())\(unitString)")
                  .foregroundStyle(value > minValue && value > maxValue ? .white : .primary)
              }
              Spacer()
              Text("Goal")
                .opacity(0)
                .foregroundStyle(.tint)
                .bold()
            }
            .font(.caption)
            .bold()
            .padding(.horizontal, 10)
            .background {
              Capsule()
                .stroke(value > maxValue ? AnyShapeStyle(.background) : AnyShapeStyle(.tint), lineWidth: 2)
                .frame(height: .barHeight - 2)
            }
            .frame(width: isWithinRange ? proxy.size.width / 1.5 : proxy.size.width / 2, height: .barHeight)

            if value > maxValue {
              Spacer()
              PillValueLabelView(title: "\(value.format())\(unitString)")
            }

            Spacer()
          }

          if value > minValue && value < maxValue {
            PillValueLabelView(title: "\(value.format())\(unitString)")
          }
        }
      }
      .frame(height: .barHeight)
      .padding(.bottom)
    }
  }
}

private extension PillRangeChart {

  var isWithinRange: Bool {
    value > minValue && value < maxValue
  }

  func currentValuePoint(proxy: GeometryProxy) -> CGFloat {
    if value < minValue {
      return offsetPoint(proxy: proxy, pointIndex: 1)
    } else if value > maxValue {
      return offsetPoint(proxy: proxy, pointIndex: 4)
    }
    return offsetPoint(proxy: proxy, pointIndex: 2.5)
  }

  func offsetPoint(proxy: GeometryProxy, pointIndex: CGFloat) -> CGFloat {
    proxy.size.width / 5 * pointIndex
  }
}

private struct PillValueLabelView: View {
  let title: String

  var body: some View {
    Text(title)
      .bold()
      .foregroundStyle(.white)
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background {
        Capsule()
          .fill(.tint)
          .overlay {
            Capsule()
              .stroke(.background, lineWidth: 3)
          }
      }
  }
}

#Preview {
  ScrollView {
    VStack {
      PillRangeChart(
        title: "Protein",
        quantityString: "34 g",
        unitString: "%",
        value: 13,
        minValue: 15,
        maxValue: 25
      )
      .tint(.protein)
      PillRangeChart(
        title: "Carbs",
        quantityString: "56 g",
        unitString: "%",
        value: 52,
        minValue: 45,
        maxValue: 60
      )
      .tint(.carbohydrates)
      PillRangeChart(
        title: "Fat",
        quantityString: "12 g",
        unitString: "%",
        value: 35,
        minValue: 20,
        maxValue: 30
      )
      .tint(.fat)
    }
    .cardContainer(fill: .background)
    .padding()
  }
  .groupedBackground()
}
