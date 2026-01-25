//
//  TodayInsightWidgetView.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-19.
//

import SwiftUI
import WidgetKit
import BloomUI
import SFSafeSymbols
import AppUI
import BloomFoundation

struct TodayInsightWidgetView: View {
  let entry: TodayInsightEntry

  @Environment(\.widgetRenderingMode) var renderingMode

  var body: some View {
    if !entry.isSubscribed {
      nonSubscriberView
    } else if entry.isLoading {
      loadingView
    } else if entry.hasError {
      errorView
    } else {
      contentView
    }
  }

  @ViewBuilder
  private var nonSubscriberView: some View {
    VStack(alignment: .leading) {
      HStack {
        Image(systemSymbol: entry.symbol)
          .font(.title3)
          .foregroundStyle(entry.color)
          .frame(square: 30)
          .padding(6)
          .if(renderingMode == .fullColor) {
            $0.background {
              RoundedRectangle(cornerRadius: 13)
                .fill(.white)
            }
          }
          .if(renderingMode != .fullColor) {
            $0.background {
              RoundedRectangle(cornerRadius: 13)
                .stroke(.fill)
            }
          }


        Text(entry.title)
          .font(.title3)
          .fontDesign(.rounded)
          .bold()

        Spacer()
      }

      Spacer(minLength: 0)

      Text(entry.content)
        .font(.body)
        .fontDesign(.rounded)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .widgetURL(URL(string: "https://api.trybloom.app/paywall?focus=todayInsights"))
    .containerBackground(entry.color.gradient, for: .widget)
  }

  @ViewBuilder
  private var contentView: some View {
    VStack(alignment: .leading) {
      HStack {
        Image(systemSymbol: entry.symbol)
          .font(.title3)
          .foregroundStyle(entry.color)
          .frame(square: 30)
          .padding(6)
          .if(renderingMode == .fullColor) {
            $0.background {
              RoundedRectangle(cornerRadius: 13)
                .fill(.white)
            }
          }
          .if(renderingMode != .fullColor) {
            $0.background {
              RoundedRectangle(cornerRadius: 13)
                .stroke(.fill)
            }
          }

        Text(entry.title)
          .font(.title3)
          .fontDesign(.rounded)
          .bold()

        Spacer()
      }

      Spacer(minLength: 0)

      Text(entry.content)
        .font(.body)
        .fontDesign(.rounded)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .widgetURL(URL(string: "https://api.trybloom.app/today"))
    .containerBackground(entry.color.gradient, for: .widget)
  }

  @ViewBuilder
  private var loadingView: some View {
    VStack(alignment: .leading) {
      HStack {
        Image(systemSymbol: entry.symbol)
          .font(.title3)
          .foregroundStyle(entry.color)
          .frame(square: 30)
          .padding(6)
          .if(renderingMode == .fullColor) {
            $0.background {
              RoundedRectangle(cornerRadius: 13)
                .fill(.white)
            }
          }
          .if(renderingMode != .fullColor) {
            $0.background {
              RoundedRectangle(cornerRadius: 13)
                .stroke(.fill)
            }
          }

        Text(entry.title)
          .font(.title3)
          .fontDesign(.rounded)
          .bold()

        Spacer()
      }

      Spacer(minLength: 0)

      Text(entry.content)
        .font(.body)
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .widgetURL(URL(string: "https://api.trybloom.app/today"))
    .containerBackground(entry.color.gradient, for: .widget)
  }

  @ViewBuilder
  private var errorView: some View {
    VStack(alignment: .leading) {
      HStack {
        Image(systemSymbol: .exclamationmarkTriangleFill)
          .font(.title3)
          .foregroundStyle(.red)
          .frame(square: 30)
          .padding(6)
          .if(renderingMode == .fullColor) {
            $0.background {
              RoundedRectangle(cornerRadius: 13)
                .fill(.white)
            }
          }
          .if(renderingMode != .fullColor) {
            $0.background {
              RoundedRectangle(cornerRadius: 13)
                .stroke(.fill)
            }
          }

        Text("Error")
          .font(.title3)
          .fontDesign(.rounded)
          .bold()

        Spacer()
      }

      Spacer(minLength: 0)

      Text("Unable to load insights. Please open the app.")
        .font(.body)
        .fontDesign(.rounded)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .widgetURL(URL(string: "https://api.trybloom.app/today"))
    .containerBackground(Color.mutedRed.gradient, for: .widget)
  }
}
