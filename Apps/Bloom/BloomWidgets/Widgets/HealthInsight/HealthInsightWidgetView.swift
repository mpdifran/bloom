//
//  HealthInsightWidgetView.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-22.
//

import SwiftUI
import WidgetKit
import BloomUI
import BloomFoundation

struct HealthInsightWidgetView: View {
  let entry: HealthInsightEntry
  @Environment(\.widgetFamily) private var widgetFamily

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
    makeWidgetContent(
      title: entry.title,
      body: entry.body,
      background: gradientForPriority(entry.priority),
      url: URL(string: "https://api.trybloom.app/paywall?focus=todayInsights")
    )
  }

  @ViewBuilder
  var contentView: some View {
    makeWidgetContent(
      title: entry.title,
      body: entry.body,
      background: gradientForPriority(entry.priority),
      url: URL(string: "https://api.trybloom.app/today")
    )
  }

  @ViewBuilder
  var loadingView: some View {
    makeWidgetContent(
      title: entry.title,
      body: entry.body,
      background: AnyShapeStyle(Color.gray.gradient),
      url: URL(string: "https://api.trybloom.app/today")
    )
  }

  @ViewBuilder
  var errorView: some View {
    makeWidgetContent(
      title: "Error",
      body: "Unable to load insights. Please open the app.",
      background: AnyShapeStyle(Color.mutedRed.gradient),
      url: URL(string: "https://api.trybloom.app/today")
    )
  }

  @ViewBuilder
  func makeWidgetContent(
    title: String,
    body: String,
    background: AnyShapeStyle,
    url: URL?
  ) -> some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(widgetFamily == .systemSmall ? .subheadline : .headline)
        .fontDesign(.rounded)
        .bold()
        .lineLimit(2)
        .multilineTextAlignment(.leading)

      Spacer(minLength: 0)

      Text(body)
        .font(.subheadline)
        .fontDesign(.rounded)

      Spacer(minLength: 0)
    }
    .foregroundStyle(.white)
    .horizontalAlignment(.leading)
    .widgetURL(url)
    .containerBackground(background, for: .widget)
  }

  func gradientForPriority(_ priority: Int) -> AnyShapeStyle {
    if priority < 4 {
      return AnyShapeStyle(LinearGradient(colors: [.mutedBlue, .mutedGreen], startPoint: .bottomLeading, endPoint: .topTrailing))
    } else if priority < 8 {
      return AnyShapeStyle(LinearGradient(colors: [.mutedYellow, .mutedRed], startPoint: .bottom, endPoint: .topLeading))
    } else {
      return AnyShapeStyle(LinearGradient(colors: [.mutedPurple, .mutedPink], startPoint: .bottom, endPoint: .top))
    }
  }
}
