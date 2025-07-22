//
//  DailyReportAlertCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-28.
//

import SFSafeSymbols
import SwiftUI

extension DailyReportAlertCell {
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
      case .morning: "Your Morning Report is ready!"
      case .evening: "Your Evening Report is ready!"
      }
    }

    var subtitle: String {
      switch self {
      case .morning: "Set your focus for today"
      case .evening: "Review your progress from today"
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

struct DailyReportAlertCell: View {
  let kind: ReportKind

  var body: some View {
    HStack {
      Image(systemSymbol: kind.symbol)
        .foregroundStyle(
          LinearGradient(
            colors: kind.colors,
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .bold()
        .fontDesign(.rounded)

      VStack(alignment: .leading) {
        Text(kind.title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        Text(kind.subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .bold()
          .fontDesign(.rounded)
      }

      Spacer()

      DisclosureIndicator()
    }
    .cardContainer(
      stroke: LinearGradient(
        colors: strokeGradientColors,
        startPoint: .bottomLeading,
        endPoint: UnitPoint(x: 0.1, y: 0)
      ),
      lineWidth: 3
    )
  }
}

private extension DailyReportAlertCell {

  var strokeGradientColors: [Color] {
    var colors = kind.colors.map { $0.opacity(0.5) }
    colors += [.clear]
    return colors
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        DailyReportAlertCell(kind: .morning)
        DailyReportAlertCell(kind: .evening)
      }
      .padding()
    }
    .groupedBackground()
  }
}
