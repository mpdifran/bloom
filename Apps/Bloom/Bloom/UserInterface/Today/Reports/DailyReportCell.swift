//
//  DailyReportCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-27.
//

import SFSafeSymbols
import SwiftUI

extension DailyReportCell {
  enum ReportKind {
    case morning
    case evening

    var symbol: SFSymbol {
      switch self {
      case .morning: .sunHorizon
      case .evening: .moon
      }
    }

    var title: String {
      switch self {
      case .morning: "Morning report"
      case .evening: "Evening report"
      }
    }

    var subtitle: String {
      switch self {
      case .morning: "Focus for today"
      case .evening: "Review your day"
      }
    }

    var colors: [Color] {
      switch self {
      case .morning: [
        .mutedPink,
        .mutedOrange,
        .mutedYellow
      ]
      case .evening: [
        .mutedPink,
        .mutedPurple,
        .mutedIndigo,
      ]
      }
    }
  }
}

struct DailyReportCell: View {
  let kind: ReportKind
  let availabilityText: String?

  init(
    kind: ReportKind,
    availabilityText: String? = nil
  ) {
    self.kind = kind
    self.availabilityText = availabilityText
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Image(systemSymbol: kind.symbol)
          .foregroundStyle(iconForegroundStyle)

        Spacer()

        if !isNotAvailable {
          DisclosureIndicator()
        }
      }
      .bold()
      .fontDesign(.rounded)

      Spacer()

      Text(kind.title)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
        .if(isNotAvailable) {
          $0.foregroundStyle(.secondary)
        }

      Group {
        if let availabilityText {
          Text(availabilityText)
        } else {
          Text(kind.subtitle)
        }
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
      .bold()
      .fontDesign(.rounded)
    }
    .frame(height: 110)
    .cardContainer(
      fill: isNotAvailable ? AnyShapeStyle(.background.opacity(0.7)) : AnyShapeStyle(.background),
      stroke: LinearGradient(
        colors: strokeGradientColors,
        startPoint: .topLeading,
        endPoint: .bottom
      ),
      lineWidth: isNotAvailable ? 0 : 3
    )
    .selectable()
  }
}

private extension DailyReportCell {

  var isNotAvailable: Bool {
    availabilityText != nil
  }

  var iconForegroundStyle: AnyShapeStyle {
    if isNotAvailable {
      AnyShapeStyle(.secondary)
    } else {
      AnyShapeStyle(
        LinearGradient(
          colors: kind.colors,
          startPoint: .top,
          endPoint: .bottom
        )
      )
    }
  }

  var strokeGradientColors: [Color] {
    var colors = kind.colors.map { $0.opacity(0.5) }
    colors += [.clear, .clear, .clear, .clear, .clear]
    return colors
  }
}

#Preview {
  ScrollView {
    VStack {
      HStack {
        DailyReportCell(kind: .morning)
        DailyReportCell(kind: .evening)
      }

      HStack {
        DailyReportCell(kind: .morning)
        DailyReportCell(kind: .evening, availabilityText: "Available in 3h")
      }
    }
    .padding()
  }
  .groupedBackground()
}
