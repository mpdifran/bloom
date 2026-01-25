//
//  LogActionsWidgetView.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-24.
//

import SwiftUI
import WidgetKit
import SFSafeSymbols
import AppIntents
import AppUI

struct LogActionsWidgetView: View {
  let entry: LogActionsEntry
  @Environment(\.widgetFamily) var widgetFamily
  @Environment(\.widgetRenderingMode) var renderingMode

  var body: some View {
    GeometryReader { geometry in
      gridLayout(in: geometry)
    }
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

private extension LogActionsWidgetView {

  @ViewBuilder
  func gridLayout(in geometry: GeometryProxy) -> some View {
    let columns = columnsForFamily
    let rows = rowsForFamily

    VStack(spacing: 8) {
      ForEach(0..<rows, id: \.self) { row in
        HStack(spacing: 8) {
          ForEach(0..<columns, id: \.self) { column in
            let index = row * columns + column
            if index < entry.actions.count {
              actionButton(for: entry.actions[index])
            } else {
              Spacer()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
          }
        }
      }
    }
  }

  var columnsForFamily: Int {
    switch widgetFamily {
    case .systemSmall:
      return 1
    case .systemMedium:
      return 2
    case .systemLarge:
      return 2
    default:
      return 2
    }
  }

  var rowsForFamily: Int {
    switch widgetFamily {
    case .systemSmall:
      return 2
    case .systemMedium:
      return 2
    case .systemLarge:
      return 4
    default:
      return 2
    }
  }

  @ViewBuilder
  func actionButton(for actionType: ActionType) -> some View {
    Button(intent: OpenActionIntent(actionType: actionType)) {
      HStack {
        Image(systemSymbol: actionType.sfSymbol)
          .font(.title3)
        Text(shortName(for: actionType))
        Spacer(minLength: 0)
      }
      .font(.subheadline)
      .foregroundStyle(.white)
      .bold()
      .fontDesign(.rounded)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(.horizontal)
      .if(renderingMode == .fullColor) {
        $0.background(actionType.color.gradient)
      }
      .if(renderingMode != .fullColor) {
        $0.background {
          RoundedRectangle(cornerRadius: 20)
            .stroke(.fill)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    .buttonStyle(.plain)
  }

  func shortName(for actionType: ActionType) -> String {
    switch actionType {
    case .magicScan:
      "Magic Scanner"
    case .barcodeScan:
      "Barcode Scanner"
    case .logVoice:
      "Voice Logger"
    case .logFood:
      "Log Food"
    case .logWater:
      "Log Water"
    case .logBowelMovement:
      "Log Bowel Movement"
    case .logPeriod:
      "Log Period"
    case .logWeight:
      "Log Weight"
    case .logBloodPressure:
      "Log Blood Pressure"
    }
  }
}
