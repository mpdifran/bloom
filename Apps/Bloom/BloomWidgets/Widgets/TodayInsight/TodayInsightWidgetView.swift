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

struct TodayInsightWidgetView: View {
  let entry: TodayInsightEntry

  var body: some View {
    if entry.isLoading {
      loadingView
    } else if entry.hasError {
      errorView
    } else {
      contentView
    }
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
          .background {
            RoundedRectangle(cornerRadius: 13)
              .fill(.white)
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
//        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .widgetURL(URL(string: "https://api.trybloom.app/today"))
    .containerBackground(entry.color.gradient, for: .widget)
  }

  @ViewBuilder
  private var loadingView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemSymbol: entry.symbol)
          .font(.title3)
          .foregroundStyle(entry.color)
          .frame(square: 30)
          .padding(6)
          .background {
            RoundedRectangle(cornerRadius: 13)
              .fill(.white)
          }

        Text(entry.title)
          .font(.title3)
          .fontDesign(.rounded)
          .bold()

        Spacer()
      }

      Text(entry.content)
        .font(.body)
        .fontDesign(.rounded)
    }
    .foregroundStyle(.white)
    .padding()
    .widgetURL(URL(string: "bloom://today"))
    .containerBackground(entry.color.gradient, for: .widget)
  }

  @ViewBuilder
  private var errorView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemSymbol: .exclamationmarkTriangleFill)
          .font(.title3)
          .foregroundStyle(.red)
          .frame(square: 30)
          .padding(6)
          .background {
            RoundedRectangle(cornerRadius: 13)
              .fill(.white)
          }

        Text("Error")
          .font(.title3)
          .fontDesign(.rounded)
          .bold()

        Spacer()
      }

      Text("Unable to load insights. Please open the app.")
        .font(.body)
        .fontDesign(.rounded)
    }
    .foregroundStyle(.white)
    .padding()
    .widgetURL(URL(string: "bloom://today"))
    .containerBackground(Color.red.gradient, for: .widget)
  }
}
