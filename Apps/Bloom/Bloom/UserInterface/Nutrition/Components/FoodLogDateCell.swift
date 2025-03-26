//
//  FoodLogDateCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-25.
//

import SwiftUI

private extension CGFloat {
  static let progressBarLineWidth: CGFloat = 4
}

extension FoodLogDateCell {
  enum State {
    case inProgress(Double)
    case complete
    case exceeded
  }
}

struct FoodLogDateCell: View {
  let date: Date
  let state: State
  let isSelected: Bool

  var body: some View {
    VStack(spacing: 4) {
      VStack(spacing: 0) {
        Text(dayOfWeek)
          .font(.caption2)
        Text(day)
          .font(.body)
      }
      .foregroundStyle(textColor)

      progressIndicator
    }
    .padding(.horizontal, 2)
    .fontWeight(.heavy)
    .fontDesign(.rounded)
    .cardContainer()
    .animation(.easeInOut, value: isSelected)
    .opacity(opacity)
  }
}

private extension FoodLogDateCell {

  var textColor: Color {
    if isSelected {
      if case .exceeded = state {
        return .mutedRed
      }
      return .primary
    }
    return .secondary
  }

  var opacity: Double {
    if date <= .now {
      return 1
    }
    return 0.4
  }

  var dayOfWeek: String {
    DateFormatter.justDayOfWeekShort.string(from: date)
  }

  var day: String {
    DateFormatter.justDay.string(from: date)
  }

  var month: String {
    DateFormatter.justShortMonth.string(from: date)
  }

  @ViewBuilder
  var progressIndicator: some View {
    switch state {
    case .inProgress(let progress):
      Image(systemSymbol: .checkmarkCircleFill)
        .font(.title2)
        .opacity(0)
        .overlay {
          ZStack {
            Circle()
              .stroke(.fill, lineWidth: .progressBarLineWidth)
            Circle()
              .trim(from: 0, to: progress)
              .stroke(.tint, style: StrokeStyle(lineWidth: .progressBarLineWidth, lineCap: .round))
              .rotationEffect(.degrees(-90))
          }
          .padding(3)
        }
    case .complete:
      Image(systemSymbol: .checkmarkCircleFill)
        .foregroundStyle(.white, .tint)
        .font(.title2)
    case .exceeded:
      Image(systemSymbol: .chevronUpCircleFill)
        .foregroundStyle(.white, .mutedRed)
        .font(.title2)
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView(.horizontal) {
      HStack {
        FoodLogDateCell(
          date: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
          state: .inProgress(0.3),
          isSelected: false
        )
        FoodLogDateCell(
          date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
          state: .exceeded,
          isSelected: false
        )
        FoodLogDateCell(
          date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
          state: .complete,
          isSelected: false
        )
        FoodLogDateCell(
          date: .now,
          state: .inProgress(0.6),
          isSelected: true
        )
        FoodLogDateCell(
          date: Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
          state: .exceeded,
          isSelected: false
        )
        FoodLogDateCell(
          date: Calendar.current.date(byAdding: .day, value: 2, to: .now)!,
          state: .inProgress(0),
          isSelected: false
        )
        FoodLogDateCell(
          date: Calendar.current.date(byAdding: .day, value: 3, to: .now)!,
          state: .inProgress(0),
          isSelected: false
        )
      }
      .padding()
    }
    .scrollIndicators(.hidden)
    .groupedBackground()
  }
}
