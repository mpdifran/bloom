//
//  HealthInsightWidgetView.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-22.
//

import SwiftUI
import WidgetKit
import BloomUI
internal import BloomFoundation

struct HealthInsightWidgetView: View {
  let entry: HealthInsightEntry

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
}

private extension HealthInsightWidgetView {

  @ViewBuilder
  var nonSubscriberView: some View {
    VStack(alignment: .leading) {
      Text(entry.title)
        .font(.headline)
        .fontDesign(.rounded)
        .bold()
        .lineLimit(2)
        .multilineTextAlignment(.leading)

      Spacer(minLength: 0)

      Text(entry.body)
        .font(.body)
        .fontDesign(.rounded)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .horizontalAlignment(.leading)
    .widgetURL(URL(string: "https://api.trybloom.app/paywall"))
    .containerBackground(gradientForPriority(entry.priority), for: .widget)
  }

  @ViewBuilder
  var contentView: some View {
    VStack(alignment: .leading) {
      Text(entry.title)
        .font(.headline)
        .fontDesign(.rounded)
        .bold()
        .lineLimit(2)
        .multilineTextAlignment(.leading)

      Spacer(minLength: 0)

      Text(entry.body)
        .font(.body)
        .fontDesign(.rounded)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .horizontalAlignment(.leading)
    .widgetURL(URL(string: "https://api.trybloom.app/today"))
    .containerBackground(gradientForPriority(entry.priority), for: .widget)
  }

  @ViewBuilder
  var loadingView: some View {
    VStack(alignment: .leading) {
      Text(entry.title)
        .font(.headline)
        .fontDesign(.rounded)
        .bold()

      Spacer(minLength: 0)

      Text(entry.body)
        .font(.body)
        .fontDesign(.rounded)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .horizontalAlignment(.leading)
    .widgetURL(URL(string: "https://api.trybloom.app/today"))
    .containerBackground(Color.gray.gradient, for: .widget)
  }

  @ViewBuilder
  var errorView: some View {
    VStack(alignment: .leading) {
      Text("Error")
        .font(.headline)
        .fontDesign(.rounded)
        .bold()

      Spacer(minLength: 0)

      Text("Unable to load insights. Please open the app.")
        .font(.body)
        .fontDesign(.rounded)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .horizontalAlignment(.leading)
    .widgetURL(URL(string: "https://api.trybloom.app/today"))
    .containerBackground(Color.mutedRed.gradient, for: .widget)
  }

  func gradientForPriority(_ priority: Int) -> AnyShapeStyle {
    if priority < 4 {
      return AnyShapeStyle(LinearGradient(colors: [.mutedBlue, .mutedGreen], startPoint: .bottom, endPoint: .top))
    } else if priority < 8 {
      return AnyShapeStyle(LinearGradient(colors: [.mutedYellow, .mutedRed], startPoint: .bottom, endPoint: .top))
    } else {
      return AnyShapeStyle(LinearGradient(colors: [.mutedPurple, .mutedPink], startPoint: .bottom, endPoint: .top))
    }
  }
}
