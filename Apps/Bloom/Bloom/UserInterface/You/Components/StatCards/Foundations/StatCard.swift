//
//  StatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI
import SFSafeSymbols


enum StatCardValueStyle {
  case leadingStandard
  case largeTinted(String?)
}
enum StatCardTrend {
  case trendingUp
  case constant
  case trendingDown
  case ok
  case warning
  case critical
}

struct StatCard<Content>: View where Content: View {
  let symbol: SFSymbol
  let title: String
  let value: String?
  let valueStyle: StatCardValueStyle
  let trend: StatCardTrend?
  let aspectRatio: CGFloat
  let layerContent: Bool
  let includePadding: Bool
  let contentBuilder: () -> Content

  init(
    symbol: SFSymbol,
    title: String,
    value: String? = nil,
    valueStyle: StatCardValueStyle = .leadingStandard,
    trend: StatCardTrend? = nil,
    aspectRatio: CGFloat = 1,
    layerContent: Bool = false,
    includePadding: Bool = true,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.symbol = symbol
    self.title = title
    self.value = value
    self.valueStyle = valueStyle
    self.trend = trend
    self.aspectRatio = aspectRatio
    self.layerContent = layerContent
    self.includePadding = includePadding
    self.contentBuilder = content
  }

  var body: some View {
    Group {
      if layerContent {
        layeredContent
      } else {
        stackedContent
      }
    }
    .cardContainer(includePadding: includePadding)
    .aspectRatio(aspectRatio, contentMode: .fit)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

private extension StatCard {

  var stackedContent: some View {
    VStack(spacing: 0) {
      headerContent
        .padding(.bottom, 8)

      contentBuilder()

      Spacer(minLength: 0)

      valueContent
        .padding(.top, 8)
    }
  }

  var layeredContent: some View {
    ZStack {
      VStack(spacing: 8) {
        headerContent

        contentBuilder()
      }

      valueContent
        .zStackAlignment(.bottom)
    }
  }

  var headerContent: some View {
    HStack {
      Image(systemSymbol: symbol)
        .foregroundStyle(.tint)

      Text(title)

      Spacer(minLength: 0)
    }
    .font(.headline)
    .bold()
    .fontDesign(.rounded)
    .fixedSize(horizontal: false, vertical: true)
    .if(!includePadding) {
      $0
        .padding(.top)
        .padding(.horizontal)
    }
  }

  @ViewBuilder
  var valueContent: some View {
    if let value {
      Group {
        switch valueStyle {
        case .largeTinted(let subtitle):
          HStack(alignment: .bottom) {
            trendContent
              .font(.largeTitle)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 0) {
              Text(value)
                .font(.largeTitle)
                .bold()
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.tint)

              if let subtitle {
                Text(subtitle)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
        case .leadingStandard:
          HStack {
            Text(value)
              .lineLimit(2)
              .minimumScaleFactor(0.5)

            Spacer(minLength: 0)

            trendContent
              .font(.title)
          }
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .if(layerContent) {
            $0.foregroundStyle(.white)
          }
        }
      }
      .if(!includePadding) {
        $0.padding()
      }
    }
  }

  @ViewBuilder
  var trendContent: some View {
    if let trend {
      Group {
        switch trend {
        case .trendingUp:
          Image(systemSymbol: .chevronUpCircleFill)
        case .constant:
          Image(systemSymbol: .minusCircleFill)
        case .trendingDown:
          Image(systemSymbol: .chevronDownCircleFill)
        case .ok:
          Image(systemSymbol: .checkmarkCircleFill)
        case .warning:
          Image(systemSymbol: .exclamationmarkTriangleFill)
        case .critical:
          Image(systemSymbol: .exclamationmarkOctagonFill)
        }
      }
      .foregroundStyle(.tint, .tint.tertiary)
      .bold()
      .fontDesign(.rounded)
    }
  }
}

extension StatCard where Content == EmptyView {

  init(
    symbol: SFSymbol,
    title: String,
    value: String? = nil,
    valueStyle: StatCardValueStyle = .leadingStandard,
    trend: StatCardTrend? = nil,
    aspectRatio: CGFloat = 1,
    layerContent: Bool = false,
    includePadding: Bool = true
  ) {
    self.symbol = symbol
    self.title = title
    self.value = value
    self.valueStyle = valueStyle
    self.trend = trend
    self.aspectRatio = aspectRatio
    self.layerContent = layerContent
    self.includePadding = includePadding
    self.contentBuilder = { EmptyView() }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        StatCard(
          symbol: .bedDoubleFill,
          title: "Bedtime",
          value: "Consistent",
          layerContent: true,
          includePadding: false) {
            Rectangle()
              .fill(.deepSleep.gradient)
              .padding(.top, 20)
          }
        StatCard(
          symbol: .clockFill,
          title: "Avg Duration",
          value: "7h 3m",
          valueStyle: .largeTinted(nil)
        )
        .tint(.coreSleep)
      }

      StatCard(
        symbol: .moonZzzFill,
        title: "Sleep Score",
        value: "No Data",
        valueStyle: .largeTinted(nil),
        aspectRatio: 2
      )

      HStack {
        StatCard(
          symbol: .lungs,
          title: "VO₂ Max",
          value: "42.5",
          valueStyle: .largeTinted("Declining"),
          trend: .trendingDown
        )
        StatCard(
          symbol: .lungs,
          title: "VO₂ Max",
          value: "42.5",
          valueStyle: .largeTinted("Constant"),
          trend: .constant
        )
      }

      HStack {
        StatCard(
          symbol: .lungs,
          title: "VO₂ Max",
          value: "42.5",
          valueStyle: .leadingStandard,
          trend: .trendingDown
        )
        StatCard(
          symbol: .heartFill,
          title: "HRV",
          value: "43 ms",
          valueStyle: .largeTinted("vs Baseline"),
          trend: .trendingUp
        ) {
          Rectangle()
            .fill(.green)
        }
      }
    }
  }
}
